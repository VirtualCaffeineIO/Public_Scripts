Important information you need while creating the app in Intune:

Install command: setup.exe /configure LanguagePack.xml

Uninstall command: setup.exe /configure remove.xml

Detection:
Registry: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail – da-dk

Value name: Path

Detection method: Value exists

Retieve the language ID here

https://learn.microsoft.com/en-us/office/2016/language/language-identifiers-optionstate-id-values
