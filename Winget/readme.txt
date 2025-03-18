1. Preparing the Winget Installation Script

To install an application using Winget, we need a PowerShell script that executes the Winget command. The script allows easy modification to deploy different applications by changing the $packageId variable before execution.


Steps to Create the IntuneWin Packages

Download the Microsoft Win32 Content Prep Tool.

Extract the tool and open a PowerShell window in that directory.

Run the following command for the install script:

.\IntuneWinAppUtil.exe -c C:\Path\To\Script -s Install-App.ps1 -o C:\Path\To\Output

Run the following command for the detection script:

.\IntuneWinAppUtil.exe -c C:\Path\To\Script -s Detect-App.ps1 -o C:\Path\To\Output

Assign and deploy both scripts in Intune.
