@echo off
setlocal
cd /d "%~dp0"

REM Remove Click-to-Run Visio only
setup.exe /configure ".\uninstall-visio.xml"

exit /b %errorlevel%
