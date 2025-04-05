# PowerShell 7 Intune Remediation Scripts

These scripts detect and enforce PowerShell 7 as the standard installation using Microsoft Intune Remediations.

## Detect-PowerShell7.ps1
- Detects if PowerShell 7 is installed (MSI/EXE/Winget).
- Triggers remediation if PowerShell 7 is installed via legacy method or missing entirely.

## Remediate-PowerShell7.ps1
- Uninstalls legacy installs of PowerShell 7 using registry uninstall strings.
- Installs the latest version using Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PowerShell7Remediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
