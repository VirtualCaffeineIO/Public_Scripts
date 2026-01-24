@echo off
setlocal
cd /d "%~dp0"

REM Remove Click-to-Run Project only
setup.exe /configure ".\uninstall-project.xml"

exit /b %errorlevel%
