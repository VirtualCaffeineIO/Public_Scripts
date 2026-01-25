Important information you need while creating the app in Intune:

Install command: setup.exe /configure project.xml

Uninstall command: setup.exe /configure remove.xml

Detection:
Registry: HKLM\SOFTWARE\Microsoft\Office\16.0\Project\InstallRoot
Value name: Path
Detection method: Value exists

Or Use the detection script
