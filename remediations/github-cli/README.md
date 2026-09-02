# GitHub CLI Intune Remediation Scripts

These scripts detect and standardize GitHub CLI installations using Microsoft Intune Remediations.

## Detect-GitHubCLI.ps1
- Detects any installed version of GitHub CLI (MSI/EXE/Winget).
- Triggers remediation if GitHub CLI is installed by any method.

## Remediate-GitHubCLI.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of GitHub CLI via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GitHubCLIRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
