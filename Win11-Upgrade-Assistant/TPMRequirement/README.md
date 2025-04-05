# TPM Requirement Script for Intune

This script is used as a **requirement rule** in Intune to ensure that only devices with **TPM 2.0 or 2.1** are allowed to install the Windows 11 upgrade.

## Usage

1. In your Intune Win32 app, go to **Requirements**
2. Add a new **Script** requirement
3. Upload `Requirement-TPM2.ps1`
4. Configure it:
   - Run script as **System**
   - 32-bit: **No**
   - Script output type: **Integer**
   - Operator: **Equals**
   - Value: `0`

## What It Does

- Returns `0` if TPM version is `2.0` or `2.1`
- Returns `1` otherwise
- Uses CIM to query the TPM on the device

Created by Virtual Caffeine IO  
https://virtualcaffeine.io