# Intune Tenant Bootstrap Runbook

## Purpose

Use this runbook to audit and establish the standard Intune/Windows Autopilot foundation in a commercial Microsoft 365 tenant. Always perform a report-only run first and retain the output with the tenant's change record.

## 1. Prepare

1. Confirm the exact Microsoft Entra tenant GUID from the target tenant's Overview page.
2. Confirm the operator has the applicable Intune and Entra roles and may grant or receive consent for the documented delegated Graph scopes.
3. Use PowerShell 7 or later.
4. Review `IntuneTenantBootstrap.psd1`, especially the canonical names, Group Tags, Autopilot settings, and ESP settings.
5. Leave `Esp.BlockingAppDisplayNames` empty unless the tenant has an explicitly approved blocking-app standard.
6. Check the tenant's existing Enrollment Status Page priorities and set `Esp.PilotPriority` and `Esp.ProductionPriority` to free values. Priority 0 belongs to the built-in default profile. A greenfield tenant can leave the shipped 1 and 2; a tenant that already runs custom ESPs cannot.
7. Choose a persistent log directory for the tenant change record.

## 2. Run the offline checks

From the package root:

```powershell
./tests/Test-Package.ps1
./tests/Test-OfflineRun.ps1
./tests/Invoke-Lint.ps1
```

No tenant is contacted by any of the three. Do not proceed with a modified
package unless every check passes.

## 3. Audit the tenant

```powershell
./Invoke-IntuneTenantBootstrap.ps1 `
    -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -ReportOnly `
    -LogDirectory 'C:\IntuneBootstrapLogs\CustomerName'
```

Use `-UseDeviceCodeAuth` when interactive browser authentication is not suitable. Add `-InstallGraphModules` only if the required authentication module is not already installed.

Authentication must report the same tenant GUID supplied on the command line. Stop immediately if the tenant is unexpected.

## 4. Review the report

The summary uses these statuses:

| Status | Meaning | Operator action |
|---|---|---|
| `Exists` | A matching object and expected configuration were found | No action |
| `Missing` | The object would be created by an apply run | Confirm that creation is intended |
| `Drift` | The name exists but important settings or assignments differ | Review manually; the script will not overwrite it |
| `Blocked` | Creation would collide with existing tenant state, currently only an occupied ESP priority | Choose a free value in the configuration file and rerun |
| `Created` | An apply run created the object or assignment | Validate and retain its recorded ID |

Resolve duplicate-name errors before applying. A duplicate is intentionally treated as unsafe.

Review all drift. Do not assume that a same-named object is safe merely because it exists. Decide outside this script whether the tenant should retain its current settings, be manually corrected, or use a deliberately renamed standard.

## 5. Apply

Use the identical tenant ID, configuration, and log location:

```powershell
./Invoke-IntuneTenantBootstrap.ps1 `
    -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -Apply `
    -LogDirectory 'C:\IntuneBootstrapLogs\CustomerName'
```

Read the confirmation target carefully. Confirm only after the authenticated tenant ID matches the intended tenant.

The run is additive. It creates missing objects and missing expected assignments. It does not update or delete existing objects, and it preserves unrelated assignments.

## 6. Validate in the portals

Allow time for Entra dynamic-group processing and Autopilot synchronization, then validate:

1. Microsoft Entra admin center: all four security groups exist, use dynamic device membership, and have membership processing enabled.
2. Intune admin center > Windows enrollment > Deployment Profiles: the three profiles exist and target the expected groups.
3. Intune admin center > Tenant administration > Filters: the three filters exist and their enrollment-profile values exactly match the plural profile names.
4. Intune admin center > Windows enrollment > Enrollment Status Page: both ESP profiles exist and target only their expected Group Tag group in addition to any pre-existing assignments that were intentionally retained.
5. Confirm each ESP allows device use after installation failure, shows a 60 minute installation timeout, carries the configured error message, and has no selected blocking apps unless names were explicitly configured. If these are blank or defaulted while the run reported `Created`, the write reached a Graph endpoint that does not carry them; capture the transcript and stop.
6. Confirm the Microsoft Intune Enrollment enterprise application exists.

## 7. Validate the existing-device intake flow

Use a non-production company-owned Windows test device that is already Intune-managed and is not registered in Autopilot.

1. Confirm `deviceOwnership` is `Company` in Entra/Intune. A personal device must never enter the intake group.
2. Confirm the device eventually joins `All Corporate Windows Devices Not in Autopilot`.
3. Confirm it receives `Onboard Existing Devices to Autopilot`.
4. Confirm the device appears in Windows Autopilot devices without a Group Tag.
5. Confirm `[ZTDId]` is populated on the Entra device and the device subsequently leaves the intake group.
6. Confirm it appears in `Autopilot Devices - All Corporate Autopilot Devices`.

This flow depends on asynchronous Microsoft services. Dynamic membership and Autopilot registration can take time; a delay alone does not mean the rule is wrong.

## 8. Re-run and retain evidence

After processing settles, run report-only again. Expected objects should report `Exists`; approved tenant differences may continue to report `Drift`.

Retain:

- the exact package version and configuration used;
- the pre-apply report;
- the apply transcript and CSV/JSON summary;
- the post-apply report;
- the operator, tenant ID, date, and approved change record.

Do not retain access tokens or paste authentication output into tickets.

## Recovery and rollback

The script does not include automated deletion because removal could affect devices already using the configuration.

If an apply run must be reversed:

1. Stop and capture the apply summary; use only object IDs marked `Created` by that run.
2. Remove new assignments before deleting their profiles or groups.
3. Check whether any device has already entered the existing-device intake group or been registered in Autopilot.
4. Do not delete Autopilot device registrations automatically. Review each affected device and its operational state.
5. Delete only objects proven to have been created by this package and approved for removal.
6. Re-run report-only and record the final state.

Deleting the Microsoft Intune Enrollment service principal is normally unnecessary and may affect enrollment. Escalate that decision to the tenant owner.

## Troubleshooting

### Wrong tenant or tenant mismatch

Use the Directory (tenant) ID GUID, not the primary domain name or subscription ID. Sign out of cached Graph sessions and rerun; the script also disconnects its process-scoped session before connecting.

### Consent or authorization error

Confirm both delegated Graph consent and the operator's Entra/Intune role. Graph scopes and directory roles are separate controls.

### HTTP 429 or temporary 5xx errors

The script retries these failures with exponential backoff. If retries are exhausted, wait and rerun. Completed creation is detected by name, so a rerun is safe provided names remain unique.

### Object reports drift

The package deliberately does not overwrite it. Compare the CSV notes and portal values against `IntuneTenantBootstrap.psd1` and `docs/DESIGN-DECISIONS.md`.

### Existing device never enters the intake group

Verify all four required facts: Windows OS, Intune/MDM management, company ownership, and absence of `[ZTDId]`. Then allow time for dynamic membership reevaluation.

### Existing device enters but is not registered

Verify that the onboarding Autopilot profile is assigned, conversion is enabled, the Intune enrollment service principal exists, and the tenant supports the workflow. Review Intune enrollment and Autopilot service status before altering the group rule.

### Blocking app name does not resolve

The configured display name must match exactly one Intune app. Rename the app or use a unique exact name. Do not paste a GUID from another tenant into the package.
