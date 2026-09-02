# Set-DesktopBackground-Azure

This script deploys a custom desktop background on Windows 11 devices via Intune.

## What It Does
- Downloads a wallpaper image from Azure Blob Storage (SAS URL required)
- Saves it to `C:\ProgramData\CompanyBackgrounds`
- Sets it as the desktop background for the currently logged-in user

## Files
- `Set-Background.ps1` — main logic to download & set background
- `Install.ps1` — wrapper to launch `Set-Background.ps1` in user context
- `Uninstall.ps1` — optional cleanup/removal script
- `Detection.ps1` — optional detection script for Intune

## Packaging Instructions
1. Replace the `<REPLACE_WITH_YOUR_SAS_URL>` placeholder in `Install.ps1`
2. Package the files using [Microsoft Win32 Content Prep Tool](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management):

```bash
IntuneWinAppUtil.exe -c . -s Install.ps1 -o .
```

3. Upload the `.intunewin` package to Intune as a **Windows app (Win32)**

## Intune App Settings
- **Install command:**
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Install.ps1
  ```
- **Uninstall command:**
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Uninstall.ps1
  ```
- **Detection rule:** Use `Detection.ps1` as a custom script

## Notes
- Ensure the blob URL is publicly accessible or properly secured with SAS
- To lock the wallpaper or prevent user changes, apply a separate configuration profile via Intune
