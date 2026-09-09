<#
.SYNOPSIS
Executes the package end to end against an offline Microsoft Graph double.

.DESCRIPTION
No network call is made and no tenant is contacted. A stand-in
Microsoft.Graph.Authentication module returns canned responses, so the whole
control path runs: configuration validation, scope selection, drift detection,
summary export, and the endpoint each object type is actually written to.

Two scenarios run:

1. Empty tenant. Every object reports Missing and no creation is attempted,
   because report-only is the default.
2. Enrollment Status Pages shaped like a Graph v1.0 response, carrying only the
   inherited enrollment-configuration properties. Under
   Set-StrictMode -Version Latest this used to raise PropertyNotFoundException
   during drift detection rather than reporting drift.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '',
    Justification = 'The offline Graph double is a module and shares its canned tenant state with this harness through the global scope. Nothing in the package itself uses global variables.')]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $packageRoot 'Invoke-IntuneTenantBootstrap.ps1'
$configuration = Import-PowerShellDataFile -LiteralPath (Join-Path $packageRoot 'IntuneTenantBootstrap.psd1')
$supportPath = Join-Path $PSScriptRoot 'support'
$tenantId = '11111111-2222-3333-4444-555555555555'

$env:PSModulePath = $supportPath + [System.IO.Path]::PathSeparator + $env:PSModulePath

$failures = [System.Collections.Generic.List[string]]::new()
$passes = [System.Collections.Generic.List[string]]::new()

function Assert-RunTest {
    param([Parameter(Mandatory)][bool]$Condition, [Parameter(Mandatory)][string]$Name)
    if ($Condition) { $passes.Add($Name) | Out-Null } else { $failures.Add($Name) | Out-Null }
}

function Invoke-OfflineScenario {
    param(
        [AllowEmptyCollection()][hashtable[]]$Seed = @(),
        [switch]$Apply
    )

    $global:OfflineGraphStore = @{}
    foreach ($entry in @($Seed)) { $global:OfflineGraphStore[$entry.Path] = @($entry.Value) }
    $global:OfflineGraphLog = [System.Collections.Generic.List[object]]::new()
    $logDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('itb-offline-' + [guid]::NewGuid().ToString('n'))

    if ($Apply) {
        & $scriptPath -TenantId $tenantId -Apply -Confirm:$false -LogDirectory $logDirectory *>&1 | Out-Null
    }
    else {
        & $scriptPath -TenantId $tenantId -ReportOnly -LogDirectory $logDirectory *>&1 | Out-Null
    }

    $summaryFile = Get-ChildItem -LiteralPath $logDirectory -Filter '*-summary.json' | Select-Object -First 1
    $summary = @(Get-Content -LiteralPath $summaryFile.FullName -Raw | ConvertFrom-Json)
    Remove-Item -LiteralPath $logDirectory -Recurse -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Summary = $summary; Log = @($global:OfflineGraphLog) }
}

# --- Scenario 1: empty tenant -------------------------------------------------
$empty = Invoke-OfflineScenario

Assert-RunTest -Condition ($empty.Summary.Count -gt 0) -Name 'Empty tenant: the run produced a summary'
Assert-RunTest -Condition (@($empty.Summary | Where-Object Status -eq 'Missing').Count -eq $empty.Summary.Count) -Name 'Empty tenant: every object reports Missing'
Assert-RunTest -Condition (@($empty.Log | Where-Object Method -ne 'GET').Count -eq 0) -Name 'Empty tenant: report-only wrote nothing'
Assert-RunTest -Condition (@($empty.Summary | Where-Object Type -eq 'DynamicGroup').Count -eq 4) -Name 'Empty tenant: four dynamic groups were evaluated'
Assert-RunTest -Condition (@($empty.Summary | Where-Object Type -eq 'DeviceFilter').Count -eq 3) -Name 'Empty tenant: three assignment filters were evaluated'
Assert-RunTest -Condition (@($empty.Summary | Where-Object Type -eq 'ESPProfile').Count -eq 2) -Name 'Empty tenant: two ESP profiles were evaluated'

$espRequests = @($empty.Log | Where-Object { $_.Uri -like '*deviceEnrollmentConfigurations*' })
Assert-RunTest -Condition ($espRequests.Count -gt 0) -Name 'Empty tenant: the ESP endpoint was called'
Assert-RunTest -Condition (@($espRequests | Where-Object { $_.Uri -like '*/beta/*' }).Count -eq $espRequests.Count) -Name 'Empty tenant: every ESP request used the beta endpoint'
Assert-RunTest -Condition (@($espRequests | Where-Object { $_.Uri -like '*/v1.0/*' }).Count -eq 0) -Name 'Empty tenant: no ESP request used the v1.0 endpoint'

# --- Scenario 2: v1.0-shaped ESP responses ------------------------------------
# A Graph v1.0 response carries only the inherited enrollment-configuration
# properties. Drift detection must report drift rather than throwing.
$espPath = 'deviceManagement/deviceEnrollmentConfigurations'
$v1ShapedEsp = @(
    @{
        Path = $espPath
        Value = @(
            [pscustomobject]@{
                '@odata.type' = '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration'
                id = 'esp-pilot'
                displayName = $configuration.Naming.PilotEsp
                description = 'Something an operator typed by hand'
                priority = 7
                version = 1
                allowNonBlockingAppInstallation = $false
            },
            [pscustomobject]@{
                '@odata.type' = '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration'
                id = 'esp-prod'
                displayName = $configuration.Naming.ProductionEsp
                description = 'Something else an operator typed by hand'
                priority = 8
                version = 1
                allowNonBlockingAppInstallation = $false
            }
        )
    }
)

$thrown = $null
try { $drifted = Invoke-OfflineScenario -Seed $v1ShapedEsp }
catch { $thrown = $_.Exception.Message }

Assert-RunTest -Condition ($null -eq $thrown) -Name "Truncated ESP response does not throw (was: $thrown)"
if ($null -eq $thrown) {
    $espRows = @($drifted.Summary | Where-Object Type -eq 'ESPProfile')
    Assert-RunTest -Condition ($espRows.Count -eq 2) -Name 'Truncated ESP response: both profiles were evaluated'
    Assert-RunTest -Condition (@($espRows | Where-Object Status -eq 'Drift').Count -eq 2) -Name 'Truncated ESP response: both profiles report Drift'
    Assert-RunTest -Condition (@($espRows | Where-Object { $_.Notes -like '*allowDeviceUseOnInstallFailure*' }).Count -eq 2) -Name 'Truncated ESP response: the missing fail-open setting is named in the drift notes'
}

# --- Scenario 3: apply against a greenfield tenant ----------------------------
$applied = Invoke-OfflineScenario -Apply

$createdRows = @($applied.Summary | Where-Object Status -eq 'Created')
Assert-RunTest -Condition ($createdRows.Count -eq $applied.Summary.Count) -Name 'Apply: every object reports Created'
Assert-RunTest -Condition (@($applied.Summary | Where-Object Type -eq 'AutopilotAssignment').Count -eq 3) -Name 'Apply: three Autopilot assignments were made'
Assert-RunTest -Condition (@($applied.Summary | Where-Object Type -eq 'ESPAssignment').Count -eq 2) -Name 'Apply: two ESP assignments were made'

$espWrites = @($applied.Log | Where-Object { $_.Method -eq 'POST' -and $_.Uri -like '*deviceEnrollmentConfigurations' })
Assert-RunTest -Condition ($espWrites.Count -eq 2) -Name 'Apply: two ESP profiles were written'
Assert-RunTest -Condition (@($espWrites | Where-Object { $_.Uri -like '*/beta/*' }).Count -eq 2) -Name 'Apply: ESP profiles were written to the beta endpoint'

# The body must actually carry the settings this package exists to guarantee.
$espBodies = @($espWrites | ForEach-Object { if ($_.Body -is [string]) { $_.Body | ConvertFrom-Json } else { $_.Body } })
foreach ($required in @('allowDeviceUseOnInstallFailure', 'installProgressTimeoutInMinutes', 'customErrorMessage', 'trackInstallProgressForAutopilotOnly')) {
    $present = @($espBodies | Where-Object { $null -ne $_.PSObject.Properties[$required] })
    Assert-RunTest -Condition ($present.Count -eq 2) -Name "Apply: ESP body carries $required"
}
Assert-RunTest -Condition (@($espBodies | Where-Object { $_.allowDeviceUseOnInstallFailure -eq $true }).Count -eq 2) -Name 'Apply: both ESP profiles are written fail-open'

# --- Scenario 4: ESP priority already taken -----------------------------------
$occupied = @(
    @{
        Path = $espPath
        Value = @(
            [pscustomobject]@{
                '@odata.type' = '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration'
                id = 'esp-incumbent'
                displayName = 'An Enrollment Status Page this package does not own'
                description = ''
                priority = [int]$configuration.Esp.PilotPriority
                version = 1
            }
        )
    }
)

$collisionError = $null
try { $null = Invoke-OfflineScenario -Seed $occupied -Apply }
catch { $collisionError = $_.Exception.Message }

Assert-RunTest -Condition ($null -ne $collisionError) -Name 'Occupied ESP priority stops an apply run'
Assert-RunTest -Condition ($collisionError -like '*An Enrollment Status Page this package does not own*') -Name 'Occupied ESP priority names the incumbent profile'

foreach ($pass in $passes) { Write-Host "PASS  $pass" -ForegroundColor Green }
foreach ($failure in $failures) { Write-Host "FAIL  $failure" -ForegroundColor Red }

Write-Host ''
Write-Host "$($passes.Count) passed; $($failures.Count) failed."
if ($failures.Count -gt 0) { exit 1 }
