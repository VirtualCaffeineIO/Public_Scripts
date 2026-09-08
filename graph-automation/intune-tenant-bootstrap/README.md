# Intune Tenant Bootstrap

Version 1.1.0

This package audits or creates a reusable Microsoft Intune and Windows Autopilot foundation in a commercial Microsoft 365 tenant. It carries no tenant-specific identifiers, so the same package runs against any tenant that meets the requirements below.

Report-only is the default. Nothing is created without `-Apply`.

## Status, read before you run this anywhere that matters

Version 1.1.0 has not been run against a live tenant since its last round of
fixes. Its three offline checks pass and they prove the control path and the
shape of every request it sends. They do not prove Microsoft Graph accepts
those bodies, because nothing in the test suite talks to Graph.

So: run it `-ReportOnly` first, which is the default and needs no switch, and do
that against a lab or test tenant before you point it at anything real. After a
first `-Apply`, open both Enrollment Status Page profiles in the Intune admin
center and confirm three things by eye: that device use is allowed after an
installation failure, that the installation timeout reads 60 minutes rather
than a default, and that the custom error message is present. If those are
blank or defaulted while the run reported `Created`, stop and report it.

That check is not paranoia. Version 1.0.0 wrote Enrollment Status Pages to the
Graph v1.0 endpoint, which silently accepts and discards every one of those
settings, so the run reported success and the profile was not configured. That
is fixed here and the fix is what has not been proven against a real tenant.

## Safety model

- Report-only is the default.
- `-Apply` is required to create anything.
- `-WhatIf` and `-Confirm` are supported.
- A tenant GUID is mandatory and is checked against the authenticated Microsoft Graph session.
- Existing objects are not updated or deleted. Differences are reported as drift.
- Duplicate display names stop the run instead of selecting an arbitrary object.
- Requests use pagination, retries for transient Graph errors, and consistency polling after creation.
- ESP assignments are added individually so unrelated existing assignments are preserved.
- An Enrollment Status Page is never created over a priority another profile already holds.

## Requirements

- PowerShell 7 or later
- An Intune-licensed commercial Microsoft 365 tenant
- Permission to consent to the delegated Microsoft Graph scopes listed below
- `Microsoft.Graph.Authentication` 2.35.1 or later

The script can install the authentication module for the current user when `-InstallGraphModules` is supplied.

## Quick start

Open PowerShell 7 in this folder. Substitute the target tenant's Microsoft Entra tenant ID.

Audit without changing the tenant:

```powershell
./Invoke-IntuneTenantBootstrap.ps1 `
    -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -ReportOnly
```

Review the console summary and the CSV/JSON files in the reported log folder. Then create only the missing objects:

```powershell
./Invoke-IntuneTenantBootstrap.ps1 `
    -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -Apply
```

For device-code sign-in, add `-UseDeviceCodeAuth`. For a first run on a workstation without the required Graph module, add `-InstallGraphModules`.

`-ReportOnly` may be omitted because report-only is the default. An apply run presents a high-impact confirmation prompt unless `-Confirm:$false` is deliberately supplied.

## Objects managed by the package

### Dynamic device groups

| Name | Purpose |
|---|---|
| `Autopilot Tag - EntraID-PilotDevice` | Devices with the `EntraID-PilotDevice` Autopilot Group Tag |
| `Autopilot Tag - EntraID-ProdDevice` | Devices with the `EntraID-ProdDevice` Autopilot Group Tag |
| `Autopilot Devices - All Corporate Autopilot Devices` | Company-owned devices that contain `[ZTDId]` |
| `All Corporate Windows Devices Not in Autopilot` | Company-owned, Intune-managed Windows devices that do not yet contain `[ZTDId]` |

Personal devices are excluded from both broad Autopilot groups by the Entra dynamic-device rule `device.deviceOwnership -eq "Company"`.

### Windows Autopilot deployment profiles

| Name | Assignment |
|---|---|
| `Deployment EntraID Pilot Devices` | Pilot Group Tag group |
| `Deployment EntraID Prod Devices` | Production Group Tag group |
| `Onboard Existing Devices to Autopilot` | Existing-device intake group |

The existing-device profile uses Autopilot's conversion setting. It does not set an OrderID/Group Tag. When the device is registered and `[ZTDId]` appears, it no longer satisfies the intake group's rule and leaves the group automatically.

This is a continuous intake mechanism, not a one-time migration list. Entra dynamic-group evaluation and Autopilot registration are asynchronous, so movement is near-real-time rather than instantaneous.

### Intune assignment filters

| Name | Enrollment profile rule |
|---|---|
| `Autopilot Filter - EntraID-PilotDevice` | `Deployment EntraID Pilot Devices` |
| `Autopilot Filter - EntraID-ProdDevice` | `Deployment EntraID Prod Devices` |
| `Autopilot Filter - EntraID-PilotAndProdDevices` | Either pilot or production profile |

The filter display names intentionally use the singular Group Tag values. Filter rules are generated from the canonical plural profile names in the configuration file, preventing spelling or singular/plural drift.

### Enrollment Status Page profiles

- `Windows 11 EntraID Pilot Devices`
- `Windows 11 EntraID Prod Devices`

Both are fail-open: `allowDeviceUseOnInstallFailure` is enabled. The default configuration has no selected blocking applications. Required applications should be assigned independently in Intune.

ESP objects are read and written through the Microsoft Graph beta endpoint. This is not a preference. The v1.0 `windows10EnrollmentCompletionPageConfiguration` resource exposes only the inherited enrollment-configuration properties plus `allowNonBlockingAppInstallation`, so a v1.0 write accepts the request and discards the fail-open setting, the installation timeout, the custom error message and the selected application list. The profile appears to have been created correctly and has not been.

Priority orders every ESP in the tenant, not only the two this package owns, and priority 0 belongs to the built-in default profile. Set `Esp.PilotPriority` and `Esp.ProductionPriority` to values the tenant has free. An apply run stops rather than creating a profile at an occupied priority, and names the profile already holding it.

If a future tenant standard requires selected ESP apps, add exact Intune app display names to `Esp.BlockingAppDisplayNames` in `IntuneTenantBootstrap.psd1`. Each name must resolve to exactly one Intune mobile-app object. Object GUIDs are deliberately not stored in the reusable package because those IDs are tenant-specific.

### Microsoft Intune Enrollment service principal

The package verifies the Microsoft first-party service principal with app ID `d4ebce55-015a-49b5-a083-c84d1797ae8c`. `Application.ReadWrite.All` is requested only during an apply run when this service principal is missing.

## Delegated Microsoft Graph scopes

Report-only uses:

- `Group.Read.All`
- `DeviceManagementServiceConfig.Read.All`
- `DeviceManagementConfiguration.Read.All`
- `Application.Read.All`
- `DeviceManagementApps.Read.All` only when blocking app names are configured

Apply uses the corresponding write scopes:

- `Group.ReadWrite.All`
- `DeviceManagementServiceConfig.ReadWrite.All`
- `DeviceManagementConfiguration.ReadWrite.All`
- `Application.Read.All`
- `Application.ReadWrite.All` only if the Intune Enrollment service principal must be created
- `DeviceManagementApps.Read.All` only when blocking app names are configured

Admin consent and applicable Intune/Entra administrator roles are still enforced by Microsoft Entra and Intune.

## Configuration

Edit `IntuneTenantBootstrap.psd1` before the report run if a tenant needs a deliberate variation. The names in the `Naming` section are the canonical contract for this package. Changing an established name causes the script to regard the new name as a different object; it does not rename the old object.

The schema requires company-owned-only existing-device intake. It cannot be disabled accidentally through configuration.

## Results and logs

By default, transcripts and summaries are written to a timestamped set of files under the operating system's temporary folder:

```text
IntuneTenantBootstrapLogs/
  IntuneTenantBootstrap-YYYYMMDD-HHMMSS.log
  IntuneTenantBootstrap-YYYYMMDD-HHMMSS-summary.csv
  IntuneTenantBootstrap-YYYYMMDD-HHMMSS-summary.json
```

Set a persistent location with `-LogDirectory`. Store the summary from the first apply run with the tenant change record; it contains the IDs returned for created objects.

## Package contents

- `Invoke-IntuneTenantBootstrap.ps1`, audit/apply entry point
- `IntuneTenantBootstrap.psd1`, names and tenant-independent settings
- `README.md`, package overview and quick start
- `docs/RUNBOOK.md`, operational procedure, validation, recovery, and troubleshooting
- `docs/DESIGN-DECISIONS.md`, locked behavior and naming decisions
- `CHANGELOG.md`, version history
- `tests/Test-Package.ps1`, offline syntax and contract checks
- `tests/Test-OfflineRun.ps1`, end-to-end run against an in-memory Graph double
- `tests/Invoke-Lint.ps1`, PSScriptAnalyzer entry point
- `tests/support/`, the offline Graph double
- `PSScriptAnalyzerSettings.psd1`, lint configuration used by the offline checks and CI
- Licensed under the repository root `LICENSE` (MIT)

## Offline tests

Neither check contacts a tenant and neither requires the real Graph module.

```powershell
./tests/Test-Package.ps1    # contract checks: names, endpoints, safety switches
./tests/Test-OfflineRun.ps1 # executes the package against an in-memory Graph double
./tests/Invoke-Lint.ps1     # PSScriptAnalyzer
```

`Test-OfflineRun.ps1` runs the real control path against a stand-in
`Microsoft.Graph.Authentication` module under `tests/support`. It covers a
greenfield report-only run, an apply run, an Enrollment Status Page response
truncated to the v1.0 property set, and an ESP priority already held by another
profile. It asserts which endpoint each write actually reached and that the ESP
body carries the fail-open setting, because a write that silently drops those
properties is the failure this package is built to prevent.

## Current boundaries

- The package targets the commercial Microsoft Graph endpoints. US Government, China, and other sovereign clouds are not supported.
- The script creates missing objects but does not reconcile drift automatically.
- It does not deploy Company Portal or any other application.
- It does not assign the three filters to unrelated Intune policies or applications; it creates them for later policy use.
- Microsoft Graph beta endpoints are used where required, for Autopilot profiles, Intune assignment filters, and Enrollment Status Page configurations. Beta resources change more often than v1.0 and the offline test pins the endpoint choice so a future edit cannot quietly move ESP back to v1.0.

For the controlled production procedure, continue with [docs/RUNBOOK.md](docs/RUNBOOK.md).
