# Manage-NewDevices-Group.ps1

### Author
**Virtual Caffeine IO**  
Website: [https://www.virtualcaffeine.io](https://www.virtualcaffeine.io)

### Version
1.0.0

---

## Overview
This Azure Automation Runbook dynamically manages an Entra ID (Azure AD) group that tracks recently enrolled Windows devices in Intune.

It ensures:
- Devices enrolled within a configurable number of days (default **24**) are **added** to a target group.
- Devices older than that threshold are **removed** automatically.

Use this group to assign **Windows Update for Business (WUfB)** policies, **security baselines**, or **onboarding tasks** only to fresh devices.

---

## How It Works
1. Queries Intune for all company-owned Windows devices enrolled in the last `MaxAgeDays`.
2. Adds matching devices to the configured Entra ID group.
3. Checks existing group members and removes devices older than `MaxAgeDays`.
4. Operates entirely via the Microsoft Graph API using an App Registration.

---

## Requirements
- **Azure Automation Account** using **PowerShell 7.2** runtime.
- **App Registration** in Entra ID with API permissions:
  - `Device.Read.All`
  - `DeviceManagementManagedDevices.Read.All`
  - `Group.ReadWrite.All`
- **Automation variables**:
  - `GraphTenantId` – your tenant ID
  - `GraphClientId` – App Registration client ID
  - `GraphClientSecret` – App Registration client secret (string)
- **Configured Entra group** for targeting:
  - Example: `All New Windows Devices` (Assigned group type)

---

## Scheduling
Run this script on a **daily schedule** in Azure Automation:
```text
Automation Account → Runbooks → Schedules → Add Schedule → Every 1 Day
