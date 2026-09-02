# Autopilot-Only Intune Script Runner

This project packages a PowerShell script to run **only during Windows Autopilot provisioning** using the Enrollment Status Page (ESP). It is designed to wrap any custom logic, such as a debloat script or setup automation, and ensure it never runs post-provisioning.

## 📂 Included Files

| File | Purpose |
|------|---------|
| `Wrapper.ps1` | Master launcher that checks if device is in Autopilot and runs the embedded script |
| `RemoveBloat.ps1` | Example payload script (replace this with your own) |
| `install.cmd` | Intune app install command (calls Wrapper.ps1) |
| `uninstall.cmd` | Dummy uninstall command |
| `detection.ps1` | Checks if the script already ran during Autopilot (via flag file) |

## ⚙️ Behavior

- Script **only executes if Autopilot provisioning is still active**
- Logs to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AutopilotOnlyApp.log`
- Sets a flag at `C:\ProgramData\AutopilotOnlyApp\script_completed.flag` once complete

## 🧪 Detection Rule

Use the following for detection in Intune:

- **Type:** Script  
- **Code:** `detection.ps1`  
- **Exit Code 0:** Already ran during Autopilot  
- **Exit Code 1:** Not yet run  

## 🛠️ How to Package for Intune

1. Use [Microsoft Win32 Content Prep Tool](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management#prepare-the-win32-app-content):

```
IntuneWinAppUtil.exe -c .\AutopilotOnlyApp -s install.cmd -o .\Output
```

2. In Intune:
   - **App type:** Win32 app  
   - **Install command:** `install.cmd`  
   - **Uninstall command:** `uninstall.cmd`  
   - **Detection rule:** Use `detection.ps1` as a script detection  
   - **Assignment:** Device group  
   - ✅ Select *"Install during device setup"* (ESP phase)

## 🔁 Swapping in a Different Script

To reuse this framework for another purpose:
- Replace `RemoveBloat.ps1` with any script you want to run only during Autopilot.
- Keep the filename the same or update `Wrapper.ps1` to point to the new filename.
