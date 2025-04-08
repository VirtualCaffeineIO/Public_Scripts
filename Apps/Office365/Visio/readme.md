Important information you need while creating the app in Intune:

Install command: setup.exe /configure visio.xml

Uninstall command: setup.exe /configure remove.xml

Detection:
Registry: HKLM\SOFTWARE\Microsoft\Office\16.0\Visio\InstallRoot
Value name: Path
Detection method: Value exists

Or Use the detection Script which looks in teh Uninstall registry locations for Visio
