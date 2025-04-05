<#
.SYNOPSIS
Detects any version of Notepad++ (legacy MSI/EXE or Winget) on the system.

.AUTHOR
Virtualized Caffeine IO
https://virtualcaffeine.io
#>

$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\NotepadPPRemediation.log"
Start-Transcript -Path $LogPath -Append -Force

$found = $false

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "*Notepad++*"
    }
    if ($apps) {
        Write-Host "Notepad++ found in registry."
        $found = $true
        break
    }
}

try {
    $wingetList = winget list | Where-Object { $_ -match "Notepad++" }
    if ($wingetList) {
        Write-Host "Notepad++ found via Winget."
        $found = $true
    }
} catch {
    Write-Warning "Winget failed to list apps"
}

Stop-Transcript

if ($found) {
    exit 1
} else {
    exit 0
}
