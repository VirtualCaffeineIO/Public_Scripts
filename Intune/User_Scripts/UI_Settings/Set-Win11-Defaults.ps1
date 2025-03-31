<#
.SYNOPSIS
    Applies Windows 11 UI customizations for both the current user and the default profile.

.DESCRIPTION
    This script modifies registry settings for the current logged-in user (HKCU) and the Default User profile (NTUSER.DAT via HKLM\TempUser).
    
    Settings applied:
    - Aligns Start Menu to the left (TaskbarAl = 0)
    - Shows file extensions (HideFileExt = 0)
    - Hides the Task View button (ShowTaskViewButton = 0)
    - Sets Search box to icon-only (SearchboxTaskbarMode = 1)
    - Enables classic right-click context menu (adds CLSID key)

    Current user changes are applied directly.
    Default user changes are applied by loading NTUSER.DAT from C:\Users\Default, modifying the hive, and unloading it.

    Output is logged to:
    C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log

.NOTES
    Author: Virtual Caffeine IO
    Created: 3-31-2025
    WWW: virtualcaffeine.io
    Intended for use with Intune Win32 apps or provisioning scripts.
#>

# Define log path
$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp `t $message"
}

# -------------------------------
# SECTION 1: HKCU - Current User
# -------------------------------
function Set-HKCUSettings {
    try {
        Write-Log "Applying settings to HKCU (current user)..."

        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $searchPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        $classicPath  = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

        if (-not (Test-Path $advancedPath)) { New-Item -Path $advancedPath -Force | Out-Null }
        Set-ItemProperty -Path $advancedPath -Name "TaskbarAl" -Type DWord -Value 0
        Set-ItemProperty -Path $advancedPath -Name "HideFileExt" -Type DWord -Value 0
        Set-ItemProperty -Path $advancedPath -Name "ShowTaskViewButton" -Type DWord -Value 0

        if (-not (Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
        Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Type DWord -Value 1

        if (-not (Test-Path $classicPath)) { New-Item -Path $classicPath -Force | Out-Null }
        New-ItemProperty -Path $classicPath -Name "(default)" -PropertyType String -Value "" -Force | Out-Null

        Write-Log "HKCU settings applied successfully."

        # Optional: restart explorer to reflect changes immediately
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Write-Log "Explorer restarted."

    } catch {
        Write-Log "ERROR applying HKCU settings: $_"
    }
}

# ---------------------------------------------
# SECTION 2: HKLM\TempUser - Default User Hive
# ---------------------------------------------
function Set-DefaultUserSettings {
    $hiveName = "HKLM\TempUser"
    $ntuserDat = "C:\Users\Default\NTUSER.DAT"

    if (!(Test-Path $ntuserDat)) {
        Write-Log "Default user profile not found. Skipping HKLM hive edit."
        return
    }

    Write-Log "Loading default user registry hive..."

    $loadResult = & reg.exe load $hiveName $ntuserDat
    Start-Sleep -Milliseconds 500

    try {
        Write-Log "Applying settings to Default User (HKLM\TempUser)..."

        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
        & reg.exe add "$hiveName\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f

        Write-Log "Default User registry settings applied successfully."

    } catch {
        Write-Log "ERROR applying settings to default user hive: $_"
    } finally {
        Write-Log "Unloading hive..."
        & reg.exe unload $hiveName | Out-Null
    }
}

# ----------------------
# MAIN EXECUTION
# ----------------------

Write-Log "`n=== Starting Win11 UI Defaults Script ==="
Set-HKCUSettings
Set-DefaultUserSettings
Write-Log "=== Script complete ===`n"

exit 0
