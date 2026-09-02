1. Preparing the Winget Installation Script

To install an application using Winget, we need a PowerShell script that executes the Winget command.
The script allows easy modification to deploy different applications by changing the $packageId variable before execution.

Save the Scripts to a common directory

Open Notepad or a PowerShell editor.
Copy/Download/Save the Winget Scripts.
Modify $packageId to the desired application.

Save the install script as Install-App.ps1.
Save the Unisntall script as Uninstall-App.ps1
Save the detection script as Detection-App.ps1

Steps to Create the IntuneWin Packages -
Since Intune does not support direct PowerShell script execution for Win32 apps, we need to package these scripts using the Microsoft Win32 Content Prep Tool.
Download the Microsoft Win32 Content Prep Tool.
https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/releases

Extract the tool and open a PowerShell window in that directory.

Run the following command for the scripts:
.\IntuneWinAppUtil.exe -c C:\Path\To\Script -s Install-App.ps1 -o C:\Path\To\Output
(You dont need the detection script packaged, but it wont hurt anything)

Assign and deploy both scripts in Intune.




Final Thoughts

Using Winget with Intune provides a flexible and efficient way to deploy and remove applications at scale. By modifying the $packageId variable, you can easily reuse these scripts for different applications. In the next article, we’ll explore updating applications using Winget in Intune.
