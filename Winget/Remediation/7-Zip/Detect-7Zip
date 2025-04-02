<#
.SYNOPSIS
Detects any version of 7-Zip (legacy MSI/EXE or Winget) on the system.

.DESCRIPTION
Used in Intune Remediations to determine whether 7-Zip needs to be removed and reinstalled. 
Checks both registry uninstall entries and Winget-installed apps.

.EXITCODES
0 = 7-Zip not found
1 = 7-Zip is installed

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\7ZipRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$found = $false

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*7-Zip*"
    }

    if ($apps) {
        Write-Host "7-Zip found in registry."
        $found = $true
        break
    }
}

if (-not $found) {
    try {
        $wingetList = winget list | Where-Object { $_ -match "7-Zip" }
        if ($wingetList) {
            Write-Host "7-Zip found via Winget."
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
