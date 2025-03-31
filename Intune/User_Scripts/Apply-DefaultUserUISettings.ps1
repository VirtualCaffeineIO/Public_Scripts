<#
This is meant to run during Autopilot to customize the start menu layouyt on Windows 11 devices
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
