<#
.SYNOPSIS
Uninstalls legacy PuTTY installs and reinstalls using Winget.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PuTTYRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$entries = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*PuTTY*"
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
            Write-Warning "Failed to uninstall PuTTY"
        }
    }
}

Start-Sleep -Seconds 3

try {
    Write-Host "Installing latest PuTTY with winget..."
    winget install PuTTY.PuTTY --silent --accept-source-agreements --accept-package-agreements
    "Installed" | Out-File -FilePath "C:\ProgramData\PuTTY-INSTALL.log" -Encoding ASCII
} catch {
    Write-Warning "Winget install failed."
    exit 1
}

Stop-Transcript
