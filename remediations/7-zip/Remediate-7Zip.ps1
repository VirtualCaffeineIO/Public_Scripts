<#
.SYNOPSIS
Removes all legacy versions of 7-Zip, then installs the latest version via Winget.

.DESCRIPTION
Designed for Intune Remediations. This script checks uninstall registry entries for MSI/EXE-based 
7-Zip installs and removes them silently. Then installs the current Winget version of 7-Zip.
Logs the entire process to Intune's logs folder for traceability.

.NOTES
- Run as SYSTEM (Intune handles this)
- Logs to: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\7ZipRemediation.log

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\7ZipRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

# 1. Find legacy 7-Zip installs
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$7zipEntries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*7-Zip*"
    }
}

# 2. Uninstall each found instance
foreach ($entry in $7zipEntries) {
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
            Write-Warning "Failed to remove 7-Zip: $($entry.DisplayName)"
        }
    }
}

Start-Sleep -Seconds 3

# 3. Reinstall latest 7-Zip via Winget
try {
    Write-Host "Installing latest 7-Zip with winget..."
    winget install 7zip.7zip --silent --accept-source-agreements --accept-package-agreements

    # Optional: flag for success
    "Installed" | Out-File -FilePath "C:\ProgramData\7Zip-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
