@echo off
setlocal

REM Ensure execution from this folder
cd /d "%~dp0"

REM Remove legacy MSI Visio if present
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Remove-MSI-Visio.ps1"

REM Install Click-to-Run Visio
setup.exe /configure ".\install-visio.xml"

exit /b %errorlevel%
