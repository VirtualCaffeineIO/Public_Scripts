<#
.SYNOPSIS
Uninstalls legacy PowerShell 7 installs and reinstalls using Winget.

.DESCRIPTION
Standardizes installation method of PowerShell 7 using Winget for update management.
Removes MSI/EXE-based installs and reinstalls via Winget.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PowerShell7Remediation.log"
Start-Transcript -Path $LogPath -Append -Force

# 1. Find legacy installs
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$entries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*PowerShell 7*"
    }
}

# 2. Uninstall each found instance
foreach ($entry in $entries) {
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
            Write-Warning "Failed to remove PowerShell 7: $($entry.DisplayName)"
        }
    }
}

Start-Sleep -Seconds 3

# 3. Reinstall latest via Winget
try {
    Write-Host "Installing latest PowerShell 7 with winget..."
    winget install Microsoft.Powershell --silent --accept-source-agreements --accept-package-agreements
    "Installed" | Out-File -FilePath "C:\ProgramData\PowerShell7-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
