:: ================================================
:: Windows 11 UI Defaults Installer - Wrapper Script
:: ================================================
::
:: This script executes the Set-Win11-Defaults.ps1 script using PowerShell
:: and logs all output to the Intune Management Extension log directory.
::
:: Purpose:
::   - Run a PowerShell script that applies Windows 11 UI tweaks
::     for both the current user (HKCU) and the default profile (HKLM\TempUser).
::
:: Behavior:
::   - Executes silently during ESP or Win32 app install
::   - Captures stdout and stderr to:
::       C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log
::   - Returns the exit code from the PowerShell script to Intune
::
:: Notes:
::   - Must be run as SYSTEM (i.e. Intune Win32 App, system context)
::   - Logging is timestamped and stored with Intune logs for easy troubleshooting
::
:: Author: Virtual Caffeine IO
:: Created: 3-31-2025
:: WWW: virtualcaffeine.io

@echo off
setlocal

set LOGFILE=C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log

echo [%DATE% %TIME%] Starting Set-Win11-Defaults.ps1 >> "%LOGFILE%"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Set-Win11-Defaults.ps1" >> "%LOGFILE%" 2>&1

set EXITCODE=%ERRORLEVEL%
echo [%DATE% %TIME%] Script exited with code %EXITCODE% >> "%LOGFILE%"
exit /b %EXITCODE%
