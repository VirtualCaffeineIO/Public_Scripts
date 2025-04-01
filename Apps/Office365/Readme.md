Development – For files you need to build the solution
Final – for your files that need to be in IntuneWIN.
Icon – for you icon that needs to go in while creating the Win32 app in Intune
Intune – for the intuneWin created file.
Media – for original media and docs like install commands and detection.
Package what is in FINAL into a IntuneWIN file and upload it to Intune as a WIN32 app.


Important information you need while creating the app in Intune:

Install command: setup.exe /configure M365Apps.xml
Uninstall command: setup.exe /configure remove.xml

Detection:
File: C:\Program Files\Microsoft Office\root\Office16
File or folder: WINWORD.EXE
Detection method: String
Operator: Greater than or equal to
Value: 16.0.16529.20226
