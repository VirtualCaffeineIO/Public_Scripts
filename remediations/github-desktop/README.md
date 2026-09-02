# GitHub Desktop Intune Remediation Scripts

These scripts detect and standardize GitHub Desktop installations using Microsoft Intune Remediations.

## Detect-GitHubDesktop.ps1
- Detects any installed version of GitHub Desktop (MSI/EXE/Winget).
- Triggers remediation if GitHub Desktop is installed by any method.

## Remediate-GitHubDesktop.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of GitHub Desktop via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GitHubDesktopRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
