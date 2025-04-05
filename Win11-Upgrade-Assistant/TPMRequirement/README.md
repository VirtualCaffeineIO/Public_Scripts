# TPM Requirement Script for Intune

This script is used as a **requirement rule** in Intune to ensure that only devices with **TPM 2.0 or 2.1** are allowed to install the Windows 11 upgrade.

## What It Does

- Uses WMI to check for TPM version
- Returns `0` if TPM 2.0 or 2.1 is detected
- Returns `1` otherwise

## How to Use This in Intune

When setting up your Win32 App in Intune:

1. Go to the **Requirements** tab
2. Click **Add**
3. Set **Requirement type**: `Script`
4. Upload: `Requirement-TPM2.ps1`
5. Configure the following options:

| Setting                                      | Value             |
|----------------------------------------------|-------------------|
| **Run this script using logged on credentials** | `No`           |
| **Enforce script signature check**             | `No`           |
| **Run script as 32-bit on 64-bit clients**     | `No`           |
| **Script output data type**                    | `Integer`      |
| **Operator**                                   | `Equals`       |
| **Value**                                      | `0`            |

This configuration ensures the upgrade will only run on devices that pass the TPM check.