<#
.SYNOPSIS
Uninstalls legacy GitHub CLI installs and reinstalls using Winget.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GitHubCLIRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$entries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*GitHub CLI*"
    }
}

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
            Write-Warning "Failed to uninstall GitHub CLI"
        }
    }
}

Start-Sleep -Seconds 3

try {
    Write-Host "Installing latest GitHub CLI with winget..."
    winget install GitHub.cli --silent --accept-source-agreements --accept-package-agreements
    "Installed" | Out-File -FilePath "C:\ProgramData\GitHubCLI-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
