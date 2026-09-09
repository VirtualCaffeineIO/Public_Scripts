# Design Decisions

Status: Agreed / Locked for package version 1.1.0.

## Tenant selection and execution safety

- A Microsoft Entra tenant GUID is mandatory at the start of every run.
- The authenticated Graph context must match that GUID.
- Report-only is the default. Creation requires the explicit `-Apply` switch and PowerShell confirmation semantics.
- Version 1 supports commercial Microsoft Graph endpoints only.
- Enrollment Status Page objects are read and written through the Microsoft Graph beta endpoint. The v1.0 `windows10EnrollmentCompletionPageConfiguration` resource exposes only the inherited enrollment-configuration properties plus `allowNonBlockingAppInstallation`. Writing the package's ESP body to v1.0 discards the fail-open setting, the installation timeout, the custom error message and the selected application list without reporting an error.
- Existing objects are not silently modified or deleted. Material differences are reported as drift.

## Existing-device Autopilot onboarding

`Onboard Existing Devices to Autopilot` is a continuous conversion profile for existing Intune-managed Windows devices that are not yet registered with Autopilot.

The intake group requires:

- Windows;
- MDM/Intune management;
- company ownership; and
- no `[ZTDId]` physical ID.

The profile converts targeted devices into Autopilot without applying an OrderID/Group Tag. After `[ZTDId]` appears, the device no longer matches the intake group and leaves automatically. Personal devices are excluded.

This is intentionally a dynamic, self-clearing intake queue. Processing is asynchronous rather than instantaneous.

## Locked naming contract

Dynamic groups:

- `Autopilot Tag - EntraID-PilotDevice`
- `Autopilot Tag - EntraID-ProdDevice`
- `Autopilot Devices - All Corporate Autopilot Devices`
- `All Corporate Windows Devices Not in Autopilot`

Autopilot profiles:

- `Deployment EntraID Pilot Devices`
- `Deployment EntraID Prod Devices`
- `Onboard Existing Devices to Autopilot`

Assignment filters:

- `Autopilot Filter - EntraID-PilotDevice`
- `Autopilot Filter - EntraID-ProdDevice`
- `Autopilot Filter - EntraID-PilotAndProdDevices`

Enrollment Status Page profiles:

- `Windows 11 EntraID Pilot Devices`
- `Windows 11 EntraID Prod Devices`

The filter names use the singular Group Tag values. Autopilot profile names remain plural because they describe profiles used by multiple devices. Filter rules are generated from the canonical profile names, so the rule strings remain aligned.

## Enrollment Status Page behavior and apps

- ESP is fail-open: a user may continue after installation failure.
- No Company Portal deployment is added.
- No tenant-specific app object GUID is embedded. The predecessor script carried one, and it was removed rather than reproduced here: an Intune mobile-app object ID is local to the tenant that created it and is meaningless, or wrong, anywhere else.
- The default selected blocking-app list is empty.
- Future selected blocking apps, if approved, are configured by exact display name and resolved to the current tenant's object IDs at run time.
- `allowNonBlockingAppInstallation` is enabled only when selected blocking apps are configured; with the default empty list it remains disabled and immaterial.

## Enrollment Status Page priority

Priority orders every Enrollment Status Page in the tenant, not only the two this package owns. Priority 0 belongs to the built-in default profile. Because the value is tenant-wide rather than per-object, creating a profile at a priority another profile already holds produces ambiguous evaluation order instead of an error, and the ambiguity surfaces later as a device receiving the wrong page.

The package therefore treats priority as configuration (`Esp.PilotPriority`, `Esp.ProductionPriority`), refuses to create over an occupied priority, and reports the holder by name so the operator chooses the free value deliberately.

## Assignments and tenant coexistence

- Missing expected assignments are added.
- Existing unrelated ESP assignments are preserved by posting an individual enrollment-configuration assignment instead of using a replace-style assignment operation.
- Extra assignments are reported as drift so the operator can verify they are intentional.
- Duplicate object display names stop the run.

## Permissions

- Read-only delegated permissions are requested during report-only runs.
- Write permissions are requested during apply runs.
- `Application.ReadWrite.All` is requested only if an apply run discovers that the Microsoft Intune Enrollment service principal is missing.
- Intune application read permission is requested only when optional blocking-app display names are configured.

## Reliability and evidence

- Every Graph collection is paged.
- HTTP 429 and retryable 5xx responses use exponential backoff.
- Newly created objects are polled until they become visible or the configured timeout expires.
- Each run produces a transcript and machine-readable CSV/JSON summary.
- Offline contract checks protect the locked names, personal-device exclusion, fail-open ESP setting, empty default app list, and removal of the legacy tenant-specific GUID.
