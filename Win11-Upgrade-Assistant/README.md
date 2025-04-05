
# Win11 Upgrade Assistant for Intune (Public Version)

Author: Virtual Caffeine IO  
Website: https://virtualcaffeine.io

---

## 🔄 Overview
This PowerShell-based package enables a user-interactive upgrade to **Windows 11 24H2** via Intune, using a **downloadable ISO hosted in Azure Blob Storage**.

The package includes:
- Script to download the ISO via **AzCopy**
- Launches `setup.exe` using **ServiceUI.exe** (user-interactive, no admin rights required)
- Automatically schedules a cleanup script to run **7 days after upgrade**
- All logs go to the **Intune log folder** for easy retrieval

---

## ✨ What You Need

- An **Azure Storage Account** with a container for your ISO
- The official **Windows 11 ISO** (24H2 or newer)
- A valid **SAS token** with read access
- A **device group** in Intune to assign the app
- Microsoft tools:
  - AzCopy (download: https://aka.ms/downloadazcopy)
  - ServiceUI.exe (from MDT toolkit)

---

## 📂 ISO Setup Instructions

### Step 1: Upload ISO to Azure
1. Go to your Azure Storage Account
2. Create a new **container** (e.g., `win11`)
3. Upload the ISO (e.g., `Win11.iso`)

### Step 2: Generate a SAS Token
1. In the container, select the ISO
2. Click **"Generate SAS"**
3. Set **permissions** to `Read (r)`
4. Set a long **expiry date** (e.g., 1 year)
5. Copy:
   - **Blob URL** (e.g., `https://yourstorage.blob.core.windows.net/win11/Win11.iso`)
   - **SAS Token** (starts with `?sv=...`)

---

## 📝 Configure the Script
Open `Launch-Win11-AzCopy.ps1` and update:

```powershell
$blobUrl = "<Your Blob URL>"      # e.g., https://yourstorage.blob.core.windows.net/win11/Win11.iso
$sasToken = "<Your SAS Token>"    # starts with ? and includes &sig=...
```

Do NOT share your real SAS token publicly.

---

## 📄 Intune Win32 App Setup

### Step 1: Prepare the App
1. Download and extract this repo
2. Replace:
   - `Files\azcopy.exe` with real AzCopy binary
   - `Files\ServiceUI.exe` with real MDT binary
3. Re-zip the full folder

### Step 2: Convert to `.intunewin`
Use the **Microsoft Win32 Content Prep Tool**:
```bash
IntuneWinAppUtil.exe -c . -s Launch-Win11-AzCopy.ps1 -o .
```

### Step 3: Create App in Intune

### ✅ Install and Uninstall Commands

#### Install Command
```powershell
powershell.exe -ExecutionPolicy Bypass -File Launch-Win11-AzCopy.ps1
```

#### Uninstall Command
No uninstaller is required for this upgrade package.  
You may leave this blank or use a simple script that returns an exit code of `0` to satisfy Intune’s requirements.

Example placeholder uninstall script:
```powershell
exit 0
```

#### Detection Rule:
- Type: **Script**
- Script:
```powershell
if (Test-Path "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt") { exit 0 } else { exit 1 }
```

---

## 🛡 Assignment
- **Assignment type**: Available for Enrolled Devices
- **Group**: Use a **device group**, not user group
- Suggested group: All corporate-owned Windows 10 devices

**Optional filter**: Exclude kiosks or special-purpose devices

---

## ✅ Post-Install Behavior
- Shows upgrade UI to logged-in user
- Downloads ISO to `C:\ProgramData\Win11Assistant`
- Logs to Intune log path:
  - `Win11Upgrade-Assistant.log`
  - `Win11Upgrade-Remediation.log`
- Creates scheduled task: `Win11Cleanup7Days`
- Cleanup script runs 7 days later and:
  - Unmounts ISO
  - Deletes ISO and `IME-Just-Ran.txt`

---

## ℹ️ Notes
- The upgrade is **interactive** — users click Next, Accept, etc.
- This process works with **non-admin users** via `ServiceUI`
- ISO download is from Azure Blob — make sure it's **fast + public only via SAS**

---

## 🚀 Credits
Created by **Virtual Caffeine IO**  
https://virtualcaffeine.io
