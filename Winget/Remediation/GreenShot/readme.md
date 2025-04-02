# Greenshot Intune Remediation Scripts

These scripts are designed for use with Microsoft Intune Remediations to detect and remediate unmanaged or legacy installations of Greenshot.

The goal is to run this ONCE then use a standard detect and remediate script to update the app.

## Scripts Included

### `Detect-Greenshot.ps1`
- Scans both 32-bit and 64-bit uninstall registry keys for any version of Greenshot.
- Also queries Winget to detect if Greenshot is installed via Winget.
- If Greenshot is found, the script exits with code `1` to trigger remediation.
- Logs its actions to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GreenshotRemediation.log`.

### `Remediate-Greenshot.ps1`
- Uninstalls all detected versions of Greenshot using their uninstall strings from the registry.
- Supports both MSI and EXE-based installs with appropriate silent switches.
- Installs the latest version of Greenshot using Winget.
- Logs all operations to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\GreenshotRemediation.log`.

## Author

**Virtualized Caffeine IO**  
[https://virtualcaffeine.io](https://virtualcaffeine.io)

---

These scripts help bring all devices to a clean and managed state where Greenshot can be updated automatically via Winget.
