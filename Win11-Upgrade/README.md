# Windows 11 In-Place Upgrade via Intune

This script performs an in-place upgrade to Windows 11 24H2 using a scheduled task and `setup.exe`.

## 🛠 How It Works
- Validates TPM 2.0
- Creates a scheduled task to run setup.exe as SYSTEM
- Waits for the upgrade to complete
- Cleans up leftover ISO files
- Includes a detection script for Intune

## 📁 Required Structure

```
Win11-Upgrade/
├── Scripts/
│   └── Upgrade-Windows11.ps1
├── Detection/
│   └── Detection-Windows11.ps1
├── Files/
│   └── Windows11Upgrade/   <-- Extract Windows 11 24H2 ISO files here
```

## 📦 Packaging for Intune

Use `IntuneWinAppUtil.exe` to package this folder:
```powershell
.\IntuneWinAppUtil.exe -c . -s Scripts\Upgrade-Windows11.ps1 -o .\Output
```

Then upload the `.intunewin` to Intune.

## ✅ Requirements
- TPM 2.0
- Windows 10 (x64)
- 25GB+ free disk
- Runs as SYSTEM