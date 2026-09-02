# Intune Remediation – Force Windows Update Reset & WUfB Scan

## Overview

This Intune remediation package is a "big hammer" for Windows Update issues on
Intune-managed Windows 10 and Windows 11 devices.

Instead of trying to decide whether a device missed a specific Patch Tuesday,
this package simply:

- Resets Windows Update state on the device
- Restarts the core update services
- Forces a new Windows Update for Business (WUfB) scan, download, and install

Use this when you want to push a clean Windows Update reset to a set of devices
and let WUfB handle patching based on the policies already applied.

This package does **not** reboot the device. Any restart requirements are
handled by your existing WUfB / Intune update ring configuration.

---

## Files

- `Detect-ForceWUReset.ps1`  
  Detection script that always returns non-compliant so the remediation runs
  every time Intune evaluates it.

- `Remediate-ForceWUReset.ps1`  
  Remediation script that:
  - Stops Windows Update related services
  - Deletes the `SoftwareDistribution` folder
  - Deletes the contents of `catroot2`
  - Restarts services
  - Triggers a fresh WUfB scan, download, and install using `UsoClient`

---

## How It Works

### Detection

`Detect-ForceWUReset.ps1` is intentionally simple:

- It always exits with code `1` (non-compliant).
- That guarantees the remediation script runs on every evaluation cycle.
- You control scope and duration by which devices you assign it to and how long
  the remediation stays active.

This is meant to be a **force tool**, not a permanent background check.

### Remediation

`Remediate-ForceWUReset.ps1` runs under the **SYSTEM** account via the Intune
Management Extension. It performs these steps:

1. Stop services:
   - `wuauserv` (Windows Update)
   - `bits` (Background Intelligent Transfer Service)
   - `cryptsvc` (Cryptographic Services)

2. Delete Windows Update state:
   - Remove `C:\Windows\SoftwareDistribution` completely
   - Delete all contents of `C:\Windows\System32\catroot2` (but not the folder itself)

3. Restart services:
   - `cryptsvc`
   - `bits`
   - `wuauserv`

4. Trigger WUfB / Windows Update activity:
   - `UsoClient StartScan`
   - `UsoClient StartDownload`
   - `UsoClient StartInstall`

It logs all activity to:

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ForceWUReset.log
