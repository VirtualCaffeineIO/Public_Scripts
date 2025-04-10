# Windows 11 UI Settings – Intune Scripts

This folder contains Intune-friendly solutions for configuring and enforcing user interface preferences on Windows 11 devices.

Each subfolder is a self-contained deployment package with:
- PowerShell scripts
- Detection logic (where needed)
- Deployment wrappers (Win32 or PR format)
- A README explaining setup and usage

---

## 📦 Available Solutions

### [`Set-Win11-Defaults-Package/`](./Set-Win11-Defaults-Package)
**Type:** Intune Win32 App  
**Purpose:** Applies UI tweaks during Autopilot or device provisioning  
**What it does:**  
- Configures both the logged-in user (`HKCU`) and the default profile (`C:\Users\Default`)
- One-time setup during ESP or onboarding
- Ideal for Autopilot and hybrid domain join scenarios

### [`Win11UI_ProactiveRemediation/`](./Win11UI_ProactiveRemediation)
**Type:** Intune Proactive Remediation  
**Purpose:** Detects and enforces UI settings post-enrollment  
**What it does:**  
- Runs on a schedule to check and fix user-side changes
- Keeps settings consistent over time
- Best paired with the above Win32 app for ongoing compliance

---

## 📝 Notes

All scripts in this folder are authored and maintained by **Virtual Caffeine IO**.  
Feel free to fork or reuse in your own environment.

📫 [virtualcaffeine.io](https://virtualcaffeine.io)
