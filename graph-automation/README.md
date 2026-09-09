# graph-automation

Tools that run against Microsoft Graph rather than on a device. They configure
a tenant or maintain objects in it. Nothing here is packaged, assigned or
deployed through Intune, and nothing here should be.

That distinction matters enough that the root README says it too. The rest of
this repository is device content: PowerShell 5.1, system context, logs to the
Intune log directory. This tree is not. It needs PowerShell 7, it authenticates
as an administrator or as an app registration, and it writes tenant
configuration.

## What is here

| Folder | What it does | Where it runs |
|---|---|---|
| [`intune-tenant-bootstrap/`](./intune-tenant-bootstrap) | Audits or creates a reusable Intune and Autopilot foundation in a commercial tenant: dynamic device groups, enrollment status page, and the supporting objects. Report-only by default. | An administrator's workstation, interactively. |
| [`manage-new-devices-group/`](./manage-new-devices-group) | Keeps an "All New Windows Devices" Entra ID group populated by enrollment age, adding devices enrolled within a threshold and removing them once they age out. | An Azure Automation runbook, on a schedule. |

## The two carry different risk

`intune-tenant-bootstrap` is defensive by construction. Report-only is the
default, `-Apply` is required to create anything, a tenant GUID is mandatory
and checked against the authenticated session, existing objects are reported as
drift rather than overwritten, and duplicate display names stop the run instead
of picking one. It ships with its own design decisions document, a runbook,
tests and a changelog. Read `docs/RUNBOOK.md` before the first run against a
tenant that has anything in it.

`manage-new-devices-group` runs unattended on a schedule with app-only
credentials, and it removes group members. Its whole job is to churn a group's
membership, so an error in the age threshold or the group ID is an error that
repeats on every run without anyone watching. Its README covers the app
registration, the required Graph permissions and the automation variables.

## What they need

| | `intune-tenant-bootstrap` | `manage-new-devices-group` |
|---|---|---|
| Host | Administrator workstation | Azure Automation account |
| PowerShell | 7 or later | Azure Automation PowerShell runtime |
| Authentication | Interactive delegated Graph consent, device code supported | App registration, client credentials |
| Module | `Microsoft.Graph.Authentication` 2.35.1 or later | Microsoft Graph REST calls directly |

Do not put an app registration secret into a script and commit it. The runbook
reads its credentials from automation variables, which is why they are
variables.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
