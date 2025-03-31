<#
This script will edith both the HKCU and Defautl user's start menu UI
#>

# -------------------------------
# SECTION 1: HKCU - Current User
# -------------------------------

function Set-HKCUSettings {
    try {
        Write-Output "Applying settings to HKCU (current user)..."

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

        # Restart Explorer to apply settings (optional)
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

    } catch {
        Write-Error "Failed to apply HKCU settings: $_"
    }
}

# ---------------------------------------------
# SECTION 2: HKLM\TempUser - Default User Hive
# ---------------------------------------------

function Set-DefaultUserSettings {
    $hiveName = "HKLM\TempUser"
    $ntuserDat = "C:\Users\Default\NTUSER.DAT"

    if (!(Test-Path $ntuserDat)) {
        Write-Warning "Default user profile not found. Skipping default user settings."
        return
    }

    Write-Output "Loading default user registry hive..."

    $loadResult = & reg.exe load $hiveName $ntuserDat
    Start-Sleep -Milliseconds 500

    try {
        Write-Output "Applying settings to Default User hive..."

        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
        & reg.exe add "$hiveName\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
        & reg.exe add "$hiveName\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f

    } catch {
        Write-Error "Failed to apply Default User settings: $_"
    } finally {
        Write-Output "Unloading default user registry hive..."
        & reg.exe unload $hiveName | Out-Null
    }
}

# ----------------------
# MAIN EXECUTION
# ----------------------

Write-Output "`n[Start] Setting Windows 11 UI defaults for current and default user profiles...`n"

Set-HKCUSettings
Set-DefaultUserSettings

Write-Output "`n[Done] All settings applied successfully.`n"
exit 0
