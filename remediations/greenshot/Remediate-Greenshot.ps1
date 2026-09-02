<#
.SYNOPSIS
Removes all legacy versions of Greenshot, then installs the latest version via Winget.

.DESCRIPTION
Designed for Intune Remediations. This script checks uninstall registry entries for MSI/EXE-based 
Greenshot installs and removes them silently. Then installs the current Winget version of Greenshot.
Logs the entire process to Intune's logs folder for traceability.

.NOTES
- Run as SYSTEM (Intune handles this)
- Logs to: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GreenshotRemediation.log

.AUTHOR
Virtualized Caffeine IO
https://www.virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GreenshotRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

# 1. Find legacy Greenshot installs
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$greenshotEntries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Greenshot*"
    }
}

# 2. Uninstall each found instance
foreach ($entry in $greenshotEntries) {
    $uninstallString = $entry.UninstallString
    if ($uninstallString) {
        if ($uninstallString -match "msiexec") {
            $silentCommand = "$uninstallString /qn /norestart"
        } else {
            $silentCommand = "$uninstallString /S"
        }

        Write-Host "Running: $silentCommand"
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $silentCommand -Wait -NoNewWindow
        } catch {
            Write-Warning "Failed to remove Greenshot: $($entry.DisplayName)"
        }
    }
}

Start-Sleep -Seconds 3

# 3. Reinstall latest Greenshot via Winget
try {
    Write-Host "Installing latest Greenshot with winget..."
    winget install Greenshot.Greenshot --silent --accept-source-agreements --accept-package-agreements

    # Optional: flag for success
    "Installed" | Out-File -FilePath "C:\ProgramData\Greenshot-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
