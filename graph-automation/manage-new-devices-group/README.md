# Manage-NewDevices-Group.ps1  
**Automated Intune Device Age Group Management**

### Author  
**Virtual Caffeine IO**  
Website: [https://virtualcaffeine.io](https://virtualcaffeine.io)

### Version  
**1.0.0**

---

## Overview
This Azure Automation runbook keeps your **“All New Windows Devices”** Entra ID group automatically updated based on device enrollment age in Intune.

It ensures:
- Devices enrolled **within X days** (default 24) are **added** to the group.
- Devices older than X days are **removed**.

Typical use case:
> Automatically target **WUfB “Immediate Update”** policies to newly enrolled devices,  
> then let them fall back into the **Production** ring after 24–30 days.

---

## ✳️ Features
- Uses **Microsoft Graph API** (no Intune connector dependency)  
- Fully works via **App Registration** (client credentials flow)  
- **Automated cleanup** of old devices  
- **Modular PowerShell** code for easy customization  
- Safe to run multiple times per day  

---

## ⚙️ Requirements

### 1. Azure Automation Account
Create a new Automation Account if you don’t already have one.

**Portal steps:**
1. Go to **Azure Portal → Automation Accounts → + Create**  
2. Configure:
   - **Name:** `Intune-Automation`
   - **Region:** (same as your tenant resources)
   - **Runtime version:** *PowerShell 7.2 (recommended)*
   - **Managed Identity:** *Off* (we’ll use app registration)
3. Click **Review + Create → Create**

---

### 2. Create App Registration
The runbook uses Microsoft Graph to manage group membership.

**Steps:**
1. Go to **Entra ID → App registrations → New registration**  
2. Name: `Intune-Automation-Graph`  
3. Supported account types: *Accounts in this organizational directory only*  
4. Click **Register**

#### API Permissions
1. Go to **API Permissions → + Add a permission → Microsoft Graph → Application permissions**  
2. Add:
   - `Device.Read.All`
   - `DeviceManagementManagedDevices.Read.All`
   - `Group.ReadWrite.All`
3. Click **Add permissions**, then **Grant admin consent**.

#### Client Secret
1. Go to **Certificates & secrets → + New client secret**
2. Name it (e.g. “AutomationSecret”) → choose **24 months** → **Add**
3. Copy the **Value** (not the Secret ID!) — this will be used in the automation variables.  
   ⚠️ Store it securely — **do not include it in scripts or documentation**.

---

### 3. Add Automation Variables
In your Automation Account:
1. Go to **Automation Account → Variables → + Add a variable**
2. Create the following **String** variables (mark `GraphClientSecret` as encrypted):

| Name | Type | Example | Encrypted |
|------|------|----------|-----------|
| `GraphTenantId` | String | `11111111-aaaa-bbbb-cccc-222222222222` | No |
| `GraphClientId` | String | `33333333-aaaa-bbbb-cccc-444444444444` | No |
| `GraphClientSecret` | String | `YOUR_CLIENT_SECRET_HERE` | ✅ Yes |

---

### 4. Import the Runbook
1. Download **Manage-NewDevices-Group.ps1** from this repo.  
2. Go to **Automation Account → Runbooks → + Create a runbook**  
3. Fill in:
   - **Name:** `Manage-NewDevices-Group`
   - **Runbook type:** *PowerShell*
   - **Runtime version:** *PowerShell 7.2*
4. Upload the `.ps1` file.
5. Click **Create → Edit → Save → Publish**.

---

### 5. Configure Parameters
The script has one optional parameter:

| Parameter | Default | Description |
|------------|----------|-------------|
| `MaxAgeDays` | `24` | The maximum age (in days) of device enrollment to remain in the group |

You can modify it per schedule or leave it at 24 for a monthly rotation window.

---

### 6. Create and Link a Schedule
Run it once daily to stay in sync.

**Steps:**
1. Open the Runbook → **Link to schedule → + Add a schedule**
2. Choose:
   - **Recurrence:** Daily  
   - **Start time:** e.g. `12:00 AM UTC`
3. Set parameters (if desired):
   - `MaxAgeDays = 30`
4. Save.

💡 *You can also trigger this manually anytime to immediately sync devices.*

---

### 7. Verify Permissions
After the first run, check:
- **Automation job output:** Logs each action (added/removed devices)
- **Target Entra group:** Devices appear/disappear according to their enrollment age

---

## 🧩 Example Workflow
| Time | Action |
|------|--------|
| Device enrolls via Autopilot | Added to “All New Windows Devices” |
| Within 24 days | Receives WUfB Ring 0 policy (immediate update) |
| After 24 days | Automatically removed, inherits Ring 3 policy |

This ensures all **newly provisioned devices** get critical updates right away, then fall back to your stable update policy.

---

## 🧰 Troubleshooting
| Issue | Fix |
|--------|-----|
| `FAILED to get Graph token` | Check App Registration secret hasn’t expired. |
| `Device not found for AzureADDeviceId` | Device may not yet sync between Intune and Entra ID. |
| Group doesn’t update | Confirm the Group ID matches the **Assigned** Entra group. |
| 403 errors | Ensure App Registration has been granted admin consent. |

---

## 📘 Logging & Maintenance
- All actions are written to the runbook job output.  
- Consider using a **Log Analytics Workspace** to centralize output.  
- Rotate the client secret before expiry.  

---

## 🧱 Integration Example (Intune WUfB)
Use this runbook’s group (`All New Windows Devices`) as the assignment target for your **“Ring 0 – Immediate”** WUfB policy:

| Setting | Ring 0 (New) | Ring 3 (Prod) |
|----------|---------------|----------------|
| Feature deferral | 0 days | 14 days |
| Quality deferral | 0 days | 7 days |
| Deadline (feature) | 2 days | 14 days |
| Deadline (quality) | 1 day | 7 days |
| Grace period | 0–1 day | 2–3 days |
| Restart behavior | Auto outside active hours | Auto outside active hours |

This pairing ensures devices are fully patched before user deployment, then automatically shift to production policies when the 24-day timer expires.

---

## 🧑‍💻 Example Manual Test
You can test it directly from the Azure Automation console:

```powershell
.\Manage-NewDevices-Group.ps1 -MaxAgeDays 7
