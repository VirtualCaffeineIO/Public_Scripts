# Win11UI_ProactiveRemediation

This folder contains a Proactive Remediation package for maintaining Windows 11 UI consistency over time.

## 🔁 What It Does

- Detects and re-applies settings for the current logged-in user
- Ensures Start Menu, File Explorer, and Desktop preferences are compliant
- Designed to run continuously after enrollment

---

## 📤 Deploying via Intune (Proactive Remediation)

1. Go to **Intune Admin Center**  
   → **Reports** → **Endpoint analytics** → **Proactive remediations**

2. Click **Create script package** and configure:
   - **Name**: `Win11 UI Defaults (Compliance)`
   - **Detection script**: `Detect-Win11Defaults.ps1`
   - **Remediation script**: `Remediate-Win11Defaults.ps1`
   - **Run this script using the logged-on credentials**: ✅ Yes (User context)

3. Set a schedule:
   - Recommended: **Once per day** or **every 8 hours**

4. Assign to user groups

---

## 📝 Logs

Remediation script logs to:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Win11PR-Remediation.log
```

## ✍️ Author

**Virtual Caffeine IO**  
[https://virtualcaffeine.io](https://virtualcaffeine.io)
