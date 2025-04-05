# PuTTY Intune Remediation Scripts

These scripts detect and standardize PuTTY installations using Microsoft Intune Remediations.

## Detect-PuTTY.ps1
- Detects any installed version of PuTTY (MSI/EXE/Winget).
- Triggers remediation if PuTTY is installed by any method.

## Remediate-PuTTY.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of PuTTY via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PuTTYRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
