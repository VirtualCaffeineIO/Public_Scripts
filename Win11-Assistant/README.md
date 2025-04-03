# Windows 11 Upgrade via Installation Assistant

This project provides a PowerShell script to facilitate the upgrade to Windows 11 using Microsoft's Installation Assistant.

## Overview

The script performs the following actions:

- **Downloads** the latest Windows 11 Installation Assistant from Microsoft's official source.
- **Initiates** the upgrade process with minimal user interaction.

## Prerequisites

- **Operating System:** Windows 10
- **TPM Version:** 2.0 or 2.1
- **Administrator Privileges:** Required to execute the script.

## Script Details

- **`Launch-Win11-Assistant.ps1`** – Main script to download and run the Installation Assistant.
- **`Detection-Windows11.ps1`** – Checks if the system is running Windows 11 version 24H2 or later.
- **`Requirement-TPM2.ps1`** – Verifies the presence of TPM version 2.0 or 2.1.

## Usage

1. **Run the installer script:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\Launch-Win11-Assistant.ps1
   ```

2. **Detection script:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\Detection-Windows11.ps1
   ```

3. **TPM check script:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\Requirement-TPM2.ps1
   ```

## Notes

- The upgrade process requires minimal user interaction.
- A system reboot will be required to complete installation.

## License

MIT License. See [LICENSE](../LICENSE) for details.

## Author

**Virtual Caffeine IO**  
[https://virtualcaffeine.io](https://virtualcaffeine.io)