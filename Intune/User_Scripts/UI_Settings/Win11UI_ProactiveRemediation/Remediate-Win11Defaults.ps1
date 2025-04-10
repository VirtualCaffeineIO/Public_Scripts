<#
.SYNOPSIS
    Remediation script for Windows 11 UI Defaults

.DESCRIPTION
    Re-applies expected registry settings in HKCU to maintain compliance.

.AUTHOR
    Virtual Caffeine IO
.WWW
    https://virtualcaffeine.io
#>

$logPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Win11PR-Remediation.log"
function Write-Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$ts `t $msg"
}

Write-Log "Starting remediation..."

try {
    $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $search   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    $desktopIcons = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    $cloudContent = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
    $classicMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    # Align Start menu to the left
    New-Item -Path $advanced -Force | Out-Null
    Set-ItemProperty -Path $advanced -Name TaskbarAl -Type DWord -Value 0

    # Show file extensions in File Explorer
    Set-ItemProperty -Path $advanced -Name HideFileExt -Type DWord -Value 0

    # Hide the Task View button from the taskbar
    Set-ItemProperty -Path $advanced -Name ShowTaskViewButton -Type DWord -Value 0

    # Prevent the Start menu from popping up automatically after upgrade
    Set-ItemProperty -Path $advanced -Name StartShownOnUpgrade -Type DWord -Value 1

    # Set Search box on taskbar to icon-only
    New-Item -Path $search -Force | Out-Null
    Set-ItemProperty -Path $search -Name SearchboxTaskbarMode -Type DWord -Value 1

    # Hide "Learn more about this picture" icon on desktop
    New-Item -Path $desktopIcons -Force | Out-Null
    Set-ItemProperty -Path $desktopIcons -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type DWord -Value 1

    # Disable Windows Spotlight collection on desktop background
    New-Item -Path $cloudContent -Force | Out-Null
    Set-ItemProperty -Path $cloudContent -Name DisableSpotlightCollectionOnDesktop -Type DWord -Value 1

    # Enable classic right-click context menu
    New-Item -Path $classicMenu -Force | Out-Null
    Set-ItemProperty -Path $classicMenu -Name "(default)" -Value "" -Force

    # Restart explorer to apply changes immediately
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Write-Log "Remediation applied successfully."

} catch {
    Write-Log "ERROR: $_"
    exit 1
}
