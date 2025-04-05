# Detection Rule for Win11 Upgrade

This script is used as a **detection rule** in Intune to determine if the Windows 11 upgrade has been launched by this package.

## What It Does

- Checks for the presence of:
  ```
  C:\ProgramData\Win11Assistant\IME-Just-Ran.txt
  ```
- This file is created when the upgrade script starts.
- If found, the app is considered **Installed**.

## Usage in Intune

1. Go to **Detection Rules** when configuring your Win32 app
2. Choose **Script**
3. Upload `Detection-Win11Upgrade.ps1`
4. Output: **Integer**
5. Operator: **Equals**
6. Value: `0`

---

Created by Virtual Caffeine IO  
https://virtualcaffeine.io