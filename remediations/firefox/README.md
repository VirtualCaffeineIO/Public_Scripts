# Mozilla Firefox Intune Remediation Scripts

These scripts detect and standardize Mozilla Firefox installations using Microsoft Intune Remediations.

## Detect-Firefox.ps1
- Detects any installed version of Firefox (MSI/EXE/Winget).
- Triggers remediation if Firefox is installed via legacy method or missing entirely.

## Remediate-Firefox.ps1
- Uninstalls Firefox if installed via MSI/EXE using registry uninstall strings.
- Installs the latest version of Firefox using Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\FirefoxRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
