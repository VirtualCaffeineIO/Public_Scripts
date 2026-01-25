@echo off
setlocal

REM Ensure execution from this folder
cd /d "%~dp0"

REM Remove legacy MSI Project if present
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Remove-MSI-Project.ps1"

REM Install Click-to-Run Project
setup.exe /configure ".\install-project.xml"

exit /b %errorlevel%
