# Changelog

## 1.1.0 - 2026-08-20

Correctness and public-release pass. The 1.0.0 package was never published.

### Fixed

- Enrollment Status Page objects are read and written through the Microsoft Graph beta endpoint. The v1.0 `windows10EnrollmentCompletionPageConfiguration` resource carries only the inherited enrollment-configuration properties plus `allowNonBlockingAppInstallation`, so the 1.0.0 write path discarded `allowDeviceUseOnInstallFailure`, `installProgressTimeoutInMinutes`, `customErrorMessage`, `selectedMobileAppIds`, `showInstallationProgress`, `installQualityUpdates`, `trackInstallProgressForAutopilotOnly`, `disableUserStatusTrackingAfterFirstUser` and `roleScopeTagIds` while reporting the profile as created. The fail-open guarantee this package exists to make was not being applied.
- ESP drift detection reads properties through the safe accessor. Under `Set-StrictMode -Version Latest` the previous direct property access raised `PropertyNotFoundException` against any response that omitted a property.
- Enrollment Status Page priority is configuration (`Esp.PilotPriority`, `Esp.ProductionPriority`) rather than the literals 1 and 2. Priority orders every ESP in the tenant, so the previous hardcoded values silently produced ambiguous evaluation order in any tenant that already ran custom pages. An apply run now stops on a collision and names the profile holding the priority.
- The nested out-of-box-experience complex type declares `#microsoft.graph.outOfBoxExperienceSetting`, matching the documented payload form.
- Graph throttling honours the `Retry-After` response header, falling back to the local backoff curve only when the header is absent.
- `Invoke-GraphRequestWithRetry` raises rather than returning nothing if the retry loop is ever exhausted without a response or a thrown error.

### Changed

- Renamed every function assigning to a PowerShell automatic variable (`$profile`, `$matches`) and every function using an unapproved verb or a plural noun. `Ensure-*` became `Initialize-*`, `Normalize-Text` became `ConvertTo-NormalizedText`, `Escape-ODataString` became `ConvertTo-ODataLiteral`.
- The apply confirmation is passed into `Invoke-TenantBootstrap` as a script block rather than reaching for `$PSCmdlet` through dynamic scope from a non-advanced function. Behaviour is unchanged.
- Configuration schema is `1.1`. A `1.0` file is rejected rather than partly honoured.

### Added

- `PSScriptAnalyzerSettings.psd1`, a GitHub Actions workflow running the offline contract test and the analyzer, `LICENSE` (MIT) and `.gitignore`.
- Offline assertions covering the ESP endpoint choice, the ESP priority contract, the documented `@odata.type` form, and the absence of assignment to automatic variables.
- The tenant-local GUID check is now a pattern scan rather than a literal comparison, so no former tenant's object ID appears anywhere in the repository, including inside the test that used to assert its absence.

## 1.0.0 - 2026-08-19

- Repackaged the tenant bootstrap as a generic, configuration-driven PowerShell 7 tool.
- Added mandatory tenant GUID input and authenticated-tenant verification.
- Made report-only the default and added explicit `-Apply`, `-WhatIf`, and `-Confirm` behavior.
- Locked canonical names for dynamic groups, Autopilot profiles, assignment filters, and ESP profiles.
- Generated filter rules from canonical profile names to prevent naming drift.
- Converted the existing-device group into a continuous company-owned Windows intake queue that clears after `[ZTDId]` appears.
- Excluded personal devices from the broad existing-device and all-Autopilot groups.
- Removed the tenant-specific ESP mobile-app object ID and defaulted selected blocking apps to none.
- Preserved fail-open ESP behavior.
- Made ESP assignment creation additive so unrelated assignments are preserved.
- Added conditional permission elevation for creation of the Microsoft Intune Enrollment service principal.
- Added Graph pagination, transient-error retries, consistency polling, duplicate-name protection, drift reporting, transcripts, and CSV/JSON summaries.
- Added an operator runbook, decision record, package overview, and offline contract checks.
