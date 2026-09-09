[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $packageRoot 'Invoke-IntuneTenantBootstrap.ps1'
$configurationPath = Join-Path $packageRoot 'IntuneTenantBootstrap.psd1'
$source = Get-Content -LiteralPath $scriptPath -Raw
$configuration = Import-PowerShellDataFile -LiteralPath $configurationPath
$failures = [System.Collections.Generic.List[string]]::new()
$passes = [System.Collections.Generic.List[string]]::new()

function Assert-PackageTest {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Name
    )
    if ($Condition) { $passes.Add($Name) | Out-Null }
    else { $failures.Add($Name) | Out-Null }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath,
    [ref]$tokens,
    [ref]$parseErrors
)
Assert-PackageTest -Condition ($parseErrors.Count -eq 0) -Name 'Main script parses without errors'
Assert-PackageTest -Condition ($configuration.SchemaVersion -eq '1.1') -Name 'Configuration schema is 1.1'

$expectedNames = @{
    PilotTagGroup             = 'Autopilot Tag - EntraID-PilotDevice'
    ProductionTagGroup        = 'Autopilot Tag - EntraID-ProdDevice'
    AllAutopilotGroup          = 'Autopilot Devices - All Corporate Autopilot Devices'
    ExistingDeviceIntakeGroup = 'All Corporate Windows Devices Not in Autopilot'
    PilotProfile               = 'Deployment EntraID Pilot Devices'
    ProductionProfile          = 'Deployment EntraID Prod Devices'
    ExistingDeviceProfile      = 'Onboard Existing Devices to Autopilot'
    PilotFilter                = 'Autopilot Filter - EntraID-PilotDevice'
    ProductionFilter           = 'Autopilot Filter - EntraID-ProdDevice'
    CombinedFilter             = 'Autopilot Filter - EntraID-PilotAndProdDevices'
    PilotEsp                   = 'Windows 11 EntraID Pilot Devices'
    ProductionEsp              = 'Windows 11 EntraID Prod Devices'
}
foreach ($key in $expectedNames.Keys) {
    Assert-PackageTest -Condition ($configuration.Naming[$key] -ceq $expectedNames[$key]) -Name "Canonical name: $key"
}

$parameterNames = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
Assert-PackageTest -Condition ($parameterNames -contains 'TenantId') -Name 'TenantId parameter exists'
Assert-PackageTest -Condition ($parameterNames -contains 'Apply') -Name 'Apply parameter exists'
Assert-PackageTest -Condition ($source.Contains("DefaultParameterSetName = 'Report'")) -Name 'Report-only parameter set is the default'
Assert-PackageTest -Condition ($source.Contains('SupportsShouldProcess')) -Name 'ShouldProcess is enabled'

Assert-PackageTest -Condition ([bool]$configuration.ExistingDeviceIntake.CompanyOwnedDevicesOnly) -Name 'Existing-device intake is company-owned only'
Assert-PackageTest -Condition ($source.Contains('(device.deviceOwnership -eq "Company")')) -Name 'Dynamic group rules enforce company ownership'
Assert-PackageTest -Condition ($source.Contains('(device.devicePhysicalIds -all (_ -notContains "[ZTDId]"))')) -Name 'Intake excludes registered Autopilot devices'
Assert-PackageTest -Condition ($source.Contains('(device.devicePhysicalIds -any (_ -startsWith "[ZTDId]"))')) -Name 'All-Autopilot group detects ZTDId'

Assert-PackageTest -Condition ([bool]$configuration.Esp.AllowDeviceUseOnInstallFailure) -Name 'ESP is fail-open'
Assert-PackageTest -Condition (@($configuration.Esp.BlockingAppDisplayNames).Count -eq 0) -Name 'Default ESP blocking-app list is empty'
# No tenant-local object GUID may be embedded anywhere in the package. The only
# GUID the package is allowed to carry is the Microsoft first-party Intune
# Enrollment application ID, which is identical in every tenant.
# The Microsoft first-party Intune Enrollment application ID is identical in
# every tenant, and the documentation placeholder is not a real object.
$allowedGuids = @(
    $configuration.IntuneEnrollmentServicePrincipal.AppId
    'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
)
$guidPattern = '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
foreach ($file in @($scriptPath, $configurationPath)) {
    $text = Get-Content -LiteralPath $file -Raw
    $stray = @([regex]::Matches($text, $guidPattern) |
        ForEach-Object { $_.Value } |
        Where-Object { $allowedGuids -notcontains $_ } |
        Sort-Object -Unique)
    Assert-PackageTest -Condition ($stray.Count -eq 0) -Name "No tenant-local GUID in $(Split-Path -Leaf $file)"
}

Assert-PackageTest -Condition ($source.Contains('$n.PilotProfile')) -Name 'Pilot filter rule is generated from canonical profile name'
Assert-PackageTest -Condition ($source.Contains('$n.ProductionProfile')) -Name 'Production filter rule is generated from canonical profile name'
Assert-PackageTest -Condition ($source.Contains('/assignments')) -Name 'Additive assignment collection endpoint is used'

# The full Enrollment Status Page settings surface exists only on beta. A v1.0
# write drops the fail-open setting and the timeout without raising an error, so
# the endpoint choice is a contract, not a preference.
Assert-PackageTest -Condition ($source -notmatch 'GraphV1/deviceManagement/deviceEnrollmentConfigurations') -Name 'ESP does not use the v1.0 enrollment-configuration endpoint'
Assert-PackageTest -Condition ($source.Contains('$script:GraphBeta/deviceManagement/deviceEnrollmentConfigurations')) -Name 'ESP uses the beta enrollment-configuration endpoint'

# Priority orders every ESP in the tenant, so it is configuration, not a literal.
Assert-PackageTest -Condition ($null -ne $configuration.Esp.PilotPriority) -Name 'Pilot ESP priority is configurable'
Assert-PackageTest -Condition ($null -ne $configuration.Esp.ProductionPriority) -Name 'Production ESP priority is configurable'
Assert-PackageTest -Condition ([int]$configuration.Esp.PilotPriority -ne [int]$configuration.Esp.ProductionPriority) -Name 'ESP priorities differ'
Assert-PackageTest -Condition ([int]$configuration.Esp.PilotPriority -ge 1 -and [int]$configuration.Esp.ProductionPriority -ge 1) -Name 'ESP priorities leave 0 to the built-in default profile'

# Nested complex types carry the hash prefix, matching the documented payload.
Assert-PackageTest -Condition ($source.Contains("'#microsoft.graph.outOfBoxExperienceSetting'")) -Name 'OOBE complex type uses the documented @odata.type form'

# PowerShell automatic variables must not be assigned.
foreach ($automatic in @('matches', 'profile', 'input', 'args', 'error')) {
    Assert-PackageTest -Condition ($source -notmatch ('\$' + $automatic + '\s*=[^=]')) -Name "No assignment to automatic variable: `$$automatic"
}
Assert-PackageTest -Condition ($source.Contains('MaximumRetryCount')) -Name 'Graph retry policy is implemented'
Assert-PackageTest -Condition ($source.Contains('@odata.nextLink')) -Name 'Graph pagination is implemented'
Assert-PackageTest -Condition ($source.Contains('Wait-ForGraphObject')) -Name 'Graph consistency polling is implemented'

foreach ($pass in $passes) { Write-Host "PASS  $pass" -ForegroundColor Green }
foreach ($failure in $failures) { Write-Host "FAIL  $failure" -ForegroundColor Red }

Write-Host ''
Write-Host "$($passes.Count) passed; $($failures.Count) failed."
if ($failures.Count -gt 0) { exit 1 }
