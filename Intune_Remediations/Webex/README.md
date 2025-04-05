# Webex Intune Remediation Scripts

These scripts detect and standardize Webex installations using Microsoft Intune Remediations.

## Detect-Webex.ps1
- Detects any installed version of Webex (MSI/EXE/Winget).
- Triggers remediation if Webex is installed by any method.

## Remediate-Webex.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of Webex via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WebexRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
