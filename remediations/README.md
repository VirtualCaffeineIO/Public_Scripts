# Intune Remediations for Standardizing Third-Party Apps

This repository contains a growing library of **Intune Remediation scripts** to detect, remove, and standardize third-party applications using [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/).

The goal is to:
- Eliminate legacy MSI/EXE installations
- Reinstall apps using Winget
- Enable reliable automated updates via weekly Winget remediation

## 🎯 Project Scope

This project is ideal for organizations that want to:
- Standardize app deployment methods across all endpoints
- Use Intune's built-in remediation framework for cleanup and enforcement
- Automate updates using Winget

Apps like **Office**, **Teams**, **OneDrive**, and **SQL Server** are explicitly excluded from Winget enforcement.

---

## 📂 Repository Structure

Each application has its own folder with:

```
📁 AppName/
├── Detect-AppName.ps1
├── Remediate-AppName.ps1
└── README.md
```

### 🔍 Detect Script

- Checks for app installed via *any* method (MSI, EXE, or Winget)
- Always triggers remediation if the app is found
- Logs to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\<AppName>Remediation.log`

### 🛠️ Remediation Script

- Removes all detected versions of the app
- Installs the latest version via Winget
- Logs all actions to the same location

---

## 🚀 Using in Intune

1. Download the remediation package folder for an app
2. In the [Intune Admin Center](https://endpoint.microsoft.com):
   - Go to **Devices > Remediations**
   - Create a new remediation script
   - Upload the `Detect-*.ps1` and `Remediate-*.ps1` files
3. Assign to a pilot group for testing
4. Monitor logs under:
   ```
   C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\
   ```

---

## 📦 Available Remediations

- [Google Chrome](./Chrome)
- [Mozilla Firefox](./Firefox)
- [PowerShell 7](./PowerShell7)
- [GitHub CLI](./GitHubCLI)
- [GitHub Desktop](./GitHubDesktop)
- [Notepad++](./NotepadPP)

More coming soon: PuTTY, Zoom, Webex, and others.

---

## 🤝 Contributions

Want to add an app? Check out [CONTRIBUTING.md](./CONTRIBUTING.md) for how to structure your submission.

---

## 👨‍💻 Author

**Virtualized Caffeine IO**  
https://virtualcaffeine.io
