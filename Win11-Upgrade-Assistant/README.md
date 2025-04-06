# Windows 11 Upgrade via Intune - Public Package

This solution enables a user-interactive Windows 11 upgrade through Microsoft Intune by downloading a Windows 11 ISO via AzCopy, mounting it, and launching `setup.exe` with ServiceUI to ensure it shows on the user's desktop.

---

## 📁 Folder Contents

| File                              | Description                                        |
|-----------------------------------|----------------------------------------------------|
| `Launch-Win11-Setup.ps1`          | Main upgrade script for Intune deployment (SYSTEM) |
| `Files\azcopy.exe`                | 🔺 You must download from Microsoft (see below)    |
| `Files\ServiceUI.exe`             | 🔺 Get from Microsoft Deployment Toolkit or OSD     |
| `Scripts\DetectionRule.ps1`       | Detection script to confirm upgrade was triggered  |

---

## ☁️ Upload ISO to Azure Blob Storage

1. Upload the Windows 11 ISO to an Azure Blob container.
2. Generate a **Blob SAS URL** with read access (valid at least 7 days).
3. Replace the placeholder in `Launch-Win11-Setup.ps1`:
   ```powershell
   $blobUrl = "<YOUR FULL BLOB SAS URL HERE>"
   ```

---

## 🔧 Intune Configuration

**Install command:**
```
powershell.exe -ExecutionPolicy Bypass -File Launch-Win11-Setup.ps1
```

**Uninstall command:**
```
exit 0
```

**Install behavior:** `System`  
**Detection rule:** Use script `Scripts\DetectionRule.ps1`  
**Assignment:** Assign to a device group of Windows 10 company-owned devices  
**Filter (optional):** Exclude known kiosk or special-role devices

---

## 🧩 Required Files

- **AzCopy**  
  📥 Download from [Microsoft's AzCopy page](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10)

- **ServiceUI.exe**  
  📥 Comes with Microsoft Deployment Toolkit (MDT) or available via OSDCloud:  
  [https://osdcloud.com](https://osdcloud.com)

---

## 📝 Logs

Log file path:
```
C:\ProgramData\Win11Assistant\Win11UpgradeAssistant.log
```

Detection marker:
```
C:\ProgramData\Win11Assistant\IME-Just-Ran.txt
```

---

## 👤 Author

**Virtual Caffeine IO**  
https://virtualcaffeine.io
