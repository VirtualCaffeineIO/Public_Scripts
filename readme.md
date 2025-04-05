# Public_Scripts

A general-purpose repository of tools, scripts, and automations — primarily focused on Microsoft Intune and Windows device management.

## 📂 What You'll Find Here

This repo contains standalone and reusable PowerShell scripts for:

- ✅ Intune Win32 app packaging & deployments
- ✅ Windows 10 → 11 upgrade workflows (ISO, cloud, and UI-based)
- ✅ Remediation scripts and detection rules
- ✅ Winget automation for third-party software
- ✅ TPM/BitLocker checks and requirement rules
- ✅ Post-upgrade cleanup and scheduled maintenance

Each folder or script includes:
- Purpose & usage
- Author info
- README where needed
- Logging support (where appropriate)

## 📌 Guidelines

- All scripts are safe to use with Microsoft Endpoint Manager (Intune)
- Most are **system-context safe** and support **non-admin users**
- Logging is directed to `C:\ProgramData` or Intune log paths when possible
- Version tags are applied per release

## 👨‍💻 Author

**Virtual Caffeine IO**  
https://virtualcaffeine.io

---

Want to contribute or request something specific? Open an issue or PR!
