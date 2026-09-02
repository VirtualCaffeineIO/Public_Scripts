# Google Chrome Intune Remediation Scripts

These scripts detect and standardize Google Chrome installations using Microsoft Intune Remediations.

## Detect-Chrome.ps1
- Detects any installed version of Google Chrome (MSI/EXE/Winget).
- Triggers remediation if Chrome is installed via legacy method or missing entirely.

## Remediate-Chrome.ps1
- Uninstalls Chrome if installed via MSI/EXE using registry uninstall strings.
- Installs the latest version of Chrome using Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ChromeRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
