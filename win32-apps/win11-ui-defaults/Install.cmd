@echo off
setlocal

set LOGFILE=C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Set-Win11Defaults.log

echo [%DATE% %TIME%] Starting Set-Win11-Defaults.ps1 >> "%LOGFILE%"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Set-Win11-Defaults.ps1" >> "%LOGFILE%" 2>&1

set EXITCODE=%ERRORLEVEL%
echo [%DATE% %TIME%] Script exited with code %EXITCODE% >> "%LOGFILE%"
exit /b %EXITCODE%
