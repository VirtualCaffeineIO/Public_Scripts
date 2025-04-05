<#
.SYNOPSIS
Detects any version of Firefox (legacy MSI/EXE or Winget) on the system.

.DESCRIPTION
Used in Intune Remediations to standardize installation via Winget. Triggers remediation if app is found via legacy install or missing entirely.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\FirefoxRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$found = $false

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Firefox*"
    }

    if ($apps) {
        Write-Host "Firefox found in registry."
        $found = $true
        break
    }
}

if (-not $found) {
    try {
        $wingetList = winget list | Where-Object { $_ -match "Firefox" }
        if ($wingetList) {
            Write-Host "Firefox not found in Winget list."
        } else {
            Write-Host "Firefox found via Winget."
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
