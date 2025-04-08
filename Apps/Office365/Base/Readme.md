Important information you need while creating the app in Intune:

With teams -
Install command: setup.exe /configure M365Apps.xml
Uninstall command: setup.exe /configure remove.xml

With OUT Teams -
Install command: setup.exe /configure M365Apps-NoTeams.xml

Detection:
File: C:\Program Files\Microsoft Office\root\Office16
File or folder: WINWORD.EXE
Detection method: String
Operator: Greater than or equal to
Value: 16.0.16529.20226


Note -

This should remove all previously installed office crap pre-installed from Dell
