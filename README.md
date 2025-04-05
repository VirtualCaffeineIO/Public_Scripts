# Detect-TPMVersion.ps1

This script checks for the presence of **TPM 2.0 or 2.1** on a Windows device.

## ✅ What It Does

- Queries the TPM version from WMI using `Win32_Tpm`
- Splits multi-version strings like `2.0, 0, 1.16`
- Returns:
  - `0` if TPM 2.0 or 2.1 is found
  - `1` otherwise

## 🧠 Use Cases

- As a **requirement rule** for Win32 apps in Intune
- As a **detection method** for upgrade policies
- For **compliance** or **reporting**

## 📦 Example: Using in Intune Requirement

| Setting                                   | Value     |
|-------------------------------------------|-----------|
| Run as 32-bit on 64-bit clients           | No        |
| Run using logged-on credentials           | No        |
| Enforce script signature check            | No        |
| Script output type                        | Integer   |
| Operator                                  | Equals    |
| Value                                     | 0         |

---

Created by Virtual Caffeine IO  
https://virtualcaffeine.io