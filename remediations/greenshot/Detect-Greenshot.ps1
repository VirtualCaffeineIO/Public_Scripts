<#
.SYNOPSIS
Detects any version of Greenshot (legacy MSI/EXE or Winget) on the system.

.DESCRIPTION
Used in Intune Remediations to determine whether Greenshot needs to be removed and reinstalled. 
Checks both registry uninstall entries and Winget-installed apps.

.EXITCODES
0 = Greenshot not found
1 = Greenshot is installed

.AUTHOR
Virtualized Caffeine IO
https://www.virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GreenshotRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$found = $false

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Greenshot*"
    }

    if ($apps) {
        Write-Host "Greenshot found in registry."
        $found = $true
        break
    }
}

if (-not $found) {
    try {
        $wingetList = winget list | Where-Object { $_ -match "Greenshot" }
        if ($wingetList) {
            Write-Host "Greenshot found via Winget."
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
    exit 0
}
