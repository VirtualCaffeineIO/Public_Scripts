<#
.SYNOPSIS
Detects any version of PowerShell 7 (legacy MSI/EXE or Winget) on the system.

.DESCRIPTION
Used in Intune Remediations to standardize installation via Winget. Triggers remediation if app is found via legacy install or missing entirely.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PowerShell7Remediation.log"
Start-Transcript -Path $LogPath -Append -Force

$found = $false

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*PowerShell 7*"
    }

    if ($apps) {
        Write-Host "PowerShell 7 found in registry."
        $found = $true
        break
    }
}

if (-not $found) {
    try {
        $wingetList = winget list | Where-Object { $_ -match "PowerShell 7" }
        if ($wingetList) {
            Write-Host "PowerShell 7 not found in Winget list."
        } else {
            Write-Host "PowerShell 7 found via Winget."
            $found = $true
        }
    } catch {
        Write-Warning "Winget failed to list apps"
    }
}

Stop-Transcript

if ($found) {
    exit 1
} else {
    exit 1
}
