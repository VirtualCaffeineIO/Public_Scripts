# autopilot/enrollment

Two scripts that register an existing device into Windows Autopilot through
Microsoft Graph, and the app registration that makes the first one possible.
Both run interactively on a technician workstation or on the device being
registered. Neither is packaged for Intune.

## Files

| File | What it does |
|---|---|
| `AppRegAutopilot.ps1` | Creates a Microsoft Entra app registration, grants it four Microsoft Graph application permissions, mints a client secret, and opens the admin consent URL. |
| `AutopilotEnroll.ps1` | Installs the community `Get-WindowsAutoPilotInfo` script from the PowerShell Gallery and calls it in `-Online` mode with that app registration's credentials, so the device it runs on is uploaded straight into the tenant's Autopilot devices. |

## AppRegAutopilot.ps1

It uses the `Az` and `AzureAD` modules, both of which it expects to already be
installed. The install lines are present but commented out at the top of the
file.

It prompts for an application name, creates the registration with
`https://portal.azure.com` as home page and reply URL, and then adds these
Microsoft Graph application role permissions by GUID:

| Permission | GUID |
|---|---|
| `DeviceManagementApps.ReadWrite.All` | `78145de6-330d-4800-a6ce-494ff2d33d07` |
| `DeviceManagementConfiguration.ReadWrite.All` | `9241abd9-d0e6-425a-bd4f-47ba86e767a4` |
| `DeviceManagementManagedDevices.ReadWrite.All` | `243333ab-4d21-40cb-a475-36241daa0842` |
| `DeviceManagementServiceConfig.ReadWrite.All` | `5ac13192-7ace-4fcf-b828-1a26f28068ee` |

Read that list before you run this. Four `ReadWrite.All` application
permissions is a large grant for a device registration task, and it is a grant
that outlives the registration work unless someone removes it.

The secret it creates expires ten days after creation, which is deliberate:
this is meant to be a short-lived credential used for a registration batch and
then deleted. The connection details are written to the clipboard and printed
to the console. There is no other copy. Record them before the window closes,
and delete the registration when the batch is finished.

## AutopilotEnroll.ps1

Four values at the top of the file are blank or defaulted and must be filled in
before use:

| Variable | Value |
|---|---|
| `$TenantID` | tenant GUID |
| `$AppID` | client ID from `AppRegAutopilot.ps1` |
| `$AppSecret` | secret value from `AppRegAutopilot.ps1` |
| `$GroupTag` | Autopilot group tag, defaults to `Autopilot` |

It then sets the execution policy to Unrestricted for the machine, installs the
NuGet package provider, installs `Get-WindowsAutoPilotInfo` from the PowerShell
Gallery, and runs it online.

Two things follow from that. The script embeds a client secret in plain text,
so it is a file to hand-carry and delete rather than to store. And it sets
`Set-ExecutionPolicy Unrestricted -Force` without restoring the previous value,
so a device it runs on is left with a weaker execution policy than it started
with.

`Get-WindowsAutoPilotInfo` is not committed here. It comes from the PowerShell
Gallery: https://www.powershellgallery.com/packages/Get-WindowsAutoPilotInfo

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
