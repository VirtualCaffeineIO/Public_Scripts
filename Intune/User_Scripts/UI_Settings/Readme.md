# Windows 11 UI Defaults – Intune Deployment Scripts

This repository contains a PowerShell script and supporting wrapper for configuring Windows 11 UI preferences using Microsoft Intune.

These scripts are designed to apply settings to both:
- The **current logged-in user** (`HKCU`)
- The **Default User profile** (`C:\Users\Default\NTUSER.DAT`), so new users inherit the same preferences

---

## 🔧 What This Configures

The following UI changes are applied to both current and future users:

| Setting                     | Value                     |
|----------------------------|---------------------------|
| Start Menu Alignment       | Left                      |
| Show File Extensions       | Enabled                   |
| Task View Button           | Hidden                    |
| Search Box                 | Icon only                 |
| Right-Click Menu           | Classic style enabled     |

---

## 📁 Files Included

| File                          | Purpose |
|-------------------------------|---------|
| `Set-Win11-Defaults.ps1`      | Core PowerShell script. Applies settings to both HKCU and Default User. Logs output to Intune's log directory. |
| `Install.cmd`                 | Wrapper script that runs the PowerShell script and captures output to `Set-Win11Defaults.log`. Required for reliable Win32 app behavior in ESP. |
| `Detection.ps1` *(optional)*  | Detection script to confirm settings were applied to the Default User profile. Used by Intune for Win32 detection logic. |

---

## 📦 Packaging for Intune

To deploy this via Intune:

1. Place all files in the same folder.
2. Package using [IntuneWinAppUtil.exe](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management):
   ```bash
   IntuneWinAppUtil.exe -c "C:\Path\To\Scripts" -s Install.cmd -o "C:\Output"
