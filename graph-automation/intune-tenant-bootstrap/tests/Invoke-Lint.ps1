<#
.SYNOPSIS
Runs PSScriptAnalyzer over the package.

.DESCRIPTION
The offline Microsoft Graph double under tests/support is excluded. It shares
state with its caller through global variables, which is what a test double
does and is not a pattern the package itself is allowed to use. Excluding the
file keeps PSAvoidGlobalVars enforced everywhere it matters.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$settings = Join-Path $packageRoot 'PSScriptAnalyzerSettings.psd1'
$excluded = Join-Path (Join-Path $packageRoot 'tests') 'support'

$files = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1' |
    Where-Object { -not $_.FullName.StartsWith($excluded, [StringComparison]::OrdinalIgnoreCase) })

$findings = @($files | ForEach-Object { Invoke-ScriptAnalyzer -Path $_.FullName -Settings $settings })

if ($findings.Count -gt 0) {
    $findings | Format-Table -AutoSize -Wrap Severity, RuleName, ScriptName, Line, Message
    Write-Host "$($findings.Count) finding(s) across $($files.Count) file(s)." -ForegroundColor Red
    exit 1
}

Write-Host "PSScriptAnalyzer clean across $($files.Count) file(s)." -ForegroundColor Green
