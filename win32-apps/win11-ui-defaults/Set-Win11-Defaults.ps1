<#
.SYNOPSIS
    Applies Windows 11 UI customizations to both the current user and the default user profile.

.DESCRIPTION
    This script sets the following UI and UX preferences:
    - Align Start Menu to the left
    - Show file extensions
    - Hide Task View button
    - Set Search to icon-only
    - Enable classic context menu
    - Prevent Start menu from opening on first logon
    - Hide "Learn more about this picture" desktop icon
    - Disable Windows Spotlight collection on desktop

    Applies changes to both:
    - HKCU (currently logged-in user)
    - HKLM\TempUser (mounted NTUSER.DAT of Default User)

    Logs actions to:
    C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log

.AUTHOR
    Virtual Caffeine IO

.WWW
    https://virtualcaffeine.io
#>

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log"
function Write-Log {
    param([string]$msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$ts `t $msg"
}

function Set-HKCUSettings {
    try {
        Write-Log "Applying HKCU settings..."

        $advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $search   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $desktopIcons = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        $cloudContent = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
        $classicMenu  = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

        New-Item -Path $advanced -Force | Out-Null
        Set-ItemProperty -Path $advanced -Name TaskbarAl -Type DWord -Value 0
        Set-ItemProperty -Path $advanced -Name HideFileExt -Type DWord -Value 0
        Set-ItemProperty -Path $advanced -Name ShowTaskViewButton -Type DWord -Value 0
        Set-ItemProperty -Path $advanced -Name StartShownOnUpgrade -Type DWord -Value 1

        New-Item -Path $search -Force | Out-Null
        Set-ItemProperty -Path $search -Name SearchboxTaskbarMode -Type DWord -Value 1

        New-Item -Path $desktopIcons -Force | Out-Null
        Set-ItemProperty -Path $desktopIcons -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type DWord -Value 1

        New-Item -Path $cloudContent -Force | Out-Null
        Set-ItemProperty -Path $cloudContent -Name DisableSpotlightCollectionOnDesktop -Type DWord -Value 1

        New-Item -Path $classicMenu -Force | Out-Null
        New-ItemProperty -Path $classicMenu -Name "(default)" -PropertyType String -Value "" -Force | Out-Null

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log "HKCU settings applied."

    } catch {
        Write-Log "ERROR applying HKCU settings: $_"
    }
}

function Set-DefaultUserSettings {
    $hiveName = "HKLM\TempUser"
    $ntuser = "C:\Users\Default\NTUSER.DAT"

    if (!(Test-Path $ntuser)) {
        Write-Log "Default user profile not found. Skipping."
        return
    }

    Write-Log "Loading default user hive..."
    reg.exe load $hiveName $ntuser | Out-Null
    Start-Sleep -Milliseconds 300

    try {
        Write-Log "Applying registry settings to Default User hive..."

        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f | Out-Null
        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f | Out-Null
        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f | Out-Null
        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v StartShownOnUpgrade /t REG_DWORD /d 1 /f | Out-Null
        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f | Out-Null
        reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" /t REG_DWORD /d 1 /f | Out-Null
        reg.exe add "$hiveName\Software\Policies\Microsoft\Windows\CloudContent" /v DisableSpotlightCollectionOnDesktop /t REG_DWORD /d 1 /f | Out-Null
        reg.exe add "$hiveName\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f | Out-Null

        Write-Log "Default user settings applied."

    } catch {
        Write-Log "ERROR applying settings to Default User hive: $_"
    } finally {
        Write-Log "Unloading registry hive..."
        reg.exe unload $hiveName | Out-Null
    }
}

Write-Log "`n=== Starting Windows 11 UI Defaults Script ==="
Set-HKCUSettings
Set-DefaultUserSettings
Write-Log "=== Script complete ===`n"
exit 0
