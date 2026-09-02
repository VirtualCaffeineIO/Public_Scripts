You will need to download -

Teams exe installer
https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409

MSTeams-x64.msix
https://go.microsoft.com/fwlink/?linkid=2196106

Install.ps1: This script will deploy the new Microsoft Teams using its offline installer.
Uninstall.ps1: This script will uninstall the new Microsoft Teams App.
Detect.ps1: This script will detect the new Microsoft Teams App on the target devices.

Package the Install.ps1, Uninstall.ps1, MSTeams-x64.msix and teamsbootstrapper.exe into a IntuneWim file with Win32 app deployment tool.

I like to create a fie structure like -
 - C:\Intune\Apps\TeamsNew\Output
 - C:\Intune\Apps\TeamsNew\Input


Create a new Win32 app in Intune -

Install command: powershell.exe -windowstyle hidden -executionpolicy bypass -command .\TeamsNew-Install.ps1

Uninstall command: powershell.exe -windowstyle hidden -executionpolicy bypass -command .\TeamsNew-Uninstall.ps1

Installation time required (mins): Keep default, which is 60 minutes.

Allow available uninstall: Yes

Install behavior: System

Device restart behavior: Select No specific action.

Set your requirements to -
Operating System Architecture: 64-bit
Minimum operating system: Select the minimum OS requirement for this deployment.

Detection Rule -

Use the detect.ps1
Rule format: Use a custom detection script.
Script file: Browse to the PowerShell script Detect.ps1.
Run script as 32-bit process on 64-bit clients: No
Enforce script signature check and run script silently: No

Assign the policy the the group of your choice

