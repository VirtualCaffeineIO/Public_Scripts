# 7-Zip Intune Remediation Scripts

These scripts are designed for use with Microsoft Intune Remediations to detect and remediate legacy or unmanaged installations of 7-Zip.

## Scripts Included

### `Detect-7Zip.ps1`
- Scans both 32-bit and 64-bit uninstall registry keys for any version of 7-Zip.
- Also queries Winget to detect if 7-Zip is installed via Winget.
- If 7-Zip is found, the script exits with code `1` to trigger remediation.
- Logs its actions to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\7ZipRemediation.log`.

### `Remediate-7Zip.ps1`
- Uninstalls all detected versions of 7-Zip using their uninstall strings from the registry.
- Supports both MSI and EXE-based installs with appropriate silent switches.
- Installs the latest version of 7-Zip using Winget.
- Logs all operations to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\7ZipRemediation.log`.

## Author

**Virtualized Caffeine IO**  
[https://virtualcaffeine.io](https://virtualcaffeine.io)

---

These scripts are intended for use in environments where 7-Zip may have been installed manually or outside of Winget and need to be standardized for lifecycle management.
