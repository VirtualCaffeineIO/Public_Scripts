# Zoom Intune Remediation Scripts

These scripts detect and standardize Zoom installations using Microsoft Intune Remediations.

## Detect-Zoom.ps1
- Detects any installed version of Zoom (MSI/EXE/Winget).
- Triggers remediation if Zoom is installed by any method.

## Remediate-Zoom.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of Zoom via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ZoomRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
