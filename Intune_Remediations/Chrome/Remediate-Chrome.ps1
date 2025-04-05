<#
.SYNOPSIS
Uninstalls legacy Chrome installs and reinstalls using Winget.

.DESCRIPTION
Standardizes installation method of Chrome using Winget for update management.
Removes MSI/EXE-based installs and reinstalls via Winget.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ChromeRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

# 1. Find legacy installs
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$entries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Chrome*"
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
            Write-Warning "Failed to remove Chrome: $($entry.DisplayName)"
        }
    }
}

Start-Sleep -Seconds 3

# 3. Reinstall latest via Winget
try {
    Write-Host "Installing latest Chrome with winget..."
    winget install Google.Chrome --silent --accept-source-agreements --accept-package-agreements
    "Installed" | Out-File -FilePath "C:\ProgramData\Chrome-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
