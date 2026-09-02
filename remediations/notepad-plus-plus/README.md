# Notepad++ Intune Remediation Scripts

These scripts detect and standardize Notepad++ installations using Microsoft Intune Remediations.

## Detect-NotepadPP.ps1
- Detects any installed version of Notepad++ (MSI/EXE/Winget).
- Triggers remediation if Notepad++ is installed by any method.

## Remediate-NotepadPP.ps1
- Uninstalls legacy versions using registry uninstall strings.
- Installs the latest version of Notepad++ via Winget.
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\NotepadPPRemediation.log`

## Author
**Virtualized Caffeine IO**  
https://virtualcaffeine.io
