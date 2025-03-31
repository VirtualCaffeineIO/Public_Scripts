<#
.SYNOPSIS
    Applies Windows 11 UI customizations for the default profile.

.DESCRIPTION
    This script modifies registry settings for the Default User profile (NTUSER.DAT via HKLM\TempUser).
    
    Settings applied:
    - Aligns Start Menu to the left (TaskbarAl = 0)
    - Shows file extensions (HideFileExt = 0)
    - Hides the Task View button (ShowTaskViewButton = 0)
    - Sets Search box to icon-only (SearchboxTaskbarMode = 1)
    - Enables classic right-click context menu (adds CLSID key)

    Default user changes are applied by loading NTUSER.DAT from C:\Users\Default, modifying the hive, and unloading it.

    Output is logged to:
    C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log

.NOTES
    Author: Virtual Caffeine IO
    Created: 3/31/2025
    WWW: virtualcaffeine.io
    Intended for use with Intune Win32 apps or provisioning scripts.
#>

$defaultUserProfile = "C:\Users\Default"
$ntUserDat = Join-Path $defaultUserProfile "NTUSER.DAT"

# Validate NTUSER.DAT exists
if (!(Test-Path $ntUserDat)) {
    Write-Host "Default profile not found. Exiting..."
    exit 1
}

# Load the Default User hive as 'TempUser'
reg.exe load "HKLM\TempUser" "$ntUserDat" | Out-Host
Start-Sleep -Seconds 1

# Apply registry changes to TempUser

# Taskbar alignment = Left
reg.exe add "HKLM\TempUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f | Out-Host

# Show file extensions
reg.exe add "HKLM\TempUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f | Out-Host

# Hide Task View button
reg.exe add "HKLM\TempUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f | Out-Host

# Search icon only
reg.exe add "HKLM\TempUser\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f | Out-Host

# Classic right-click context menu
reg.exe add "HKLM\TempUser\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f | Out-Host

# Unload hive
Start-Sleep -Seconds 1
reg.exe unload "HKLM\TempUser" | Out-Host
