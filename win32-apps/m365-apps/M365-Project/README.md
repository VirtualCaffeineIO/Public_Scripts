# M365-Project

Project desktop app, the Project Online Desktop Client that comes with Planner and
Project Plan 3 or Planner and Project Plan 5. Add-on to an existing Microsoft 365
Apps installation. Offered in Company Portal as an available install.

## Plan 3 against Plan 5, and why there is only one package

Microsoft Learn lists `ProjectProRetail` as the supported ODT product ID for the
subscription Project desktop app and does not split it by plan. Learn's licensing
reference shows Planner and Project Plan 3 and Planner and Project Plan 5 both
carrying the `PROJECT_CLIENT_SUBSCRIPTION` service plan, described as "Project
Online Desktop Client". The plan difference is a service entitlement difference,
not a different installer. One package covers both. What differs is who you assign
it to.

## Worked example estate

| Property | Value used here | Where to change it |
| --- | --- | --- |
| Update channel | inherited from the device, not set | intentionally absent from the XML |
| Architecture | inherited from the device, not set | intentionally absent from the XML |
| Base language | inherited via `MatchInstalled` | `TargetProduct` in the XML |
| Requestable extra language | da-dk, inherited automatically | nothing to change |
| Product ID | `ProjectProRetail` | XML and `$ExpectedProductId`, and they must agree |
| Version | `MatchInstalled` | `Version` in the XML |

The base estate runs Monthly Enterprise Channel, 64-bit, en-us, with da-dk on
request. This package does not depend on any of that. It reads the device and
matches it.

## The channel trap this package exists to avoid

The previous version hard-coded `Channel="MonthlyEnterprise"` with no `Version`.
Installing Project on a Current Channel device did not error. It re-channelled the
device's entire Office installation at the next update cycle, days after the
Project request, with nothing linking the two events.

Per the ODT reference on Learn, when Microsoft 365 Apps is already installed and
`Channel` is not specified, the ODT matches the channel of the existing
installation, and the same holds for architecture when `OfficeClientEdition` is
omitted. So this package specifies neither.

### A contradiction in the documentation

- The ODT configuration reference states: "When you use `Version="MatchInstalled"`, the Channel attribute is required."
- The Microsoft 365 Apps Rangers best practices page, "Build dynamic, lean, and universal packages for Microsoft 365 Apps", uses adding Project to an existing Office as its primary worked example and shows `Version="MatchInstalled"` with **no** `Channel`, explaining that omitting `Channel` is what makes the package universal.

This package follows the best practices page, because it addresses this exact
scenario and because supplying `Channel` causes the harm being fixed. The
contradiction is real and this repository states it rather than hiding it.
Validate on a device that is **not** on Monthly Enterprise Channel before broad
release.

## Language behaviour

`<Language ID="MatchInstalled" TargetProduct="All" />` installs Project in the same
languages already present across every installed product. `TargetProduct="All"` is
used rather than a specific product ID so this one file works whether the base is
`O365ProPlusRetail` or `O365BusinessRetail`.

Constraint from Learn: Project supports the same language set Visio does, which is
narrower than the Microsoft 365 Apps set. English (United Kingdom), French (Canada)
and Spanish (Mexico) are supported by Microsoft 365 Apps but not by Project or
Visio. If those base languages exist in your estate, test against one of those
devices before broad release.

## Files

| File | Purpose |
| --- | --- |
| `install-M365-Project.xml` | ODT configuration for install |
| `uninstall-M365-Project.xml` | ODT configuration for removal |
| `Detect-M365Project.ps1` | Intune custom detection script |

Add `setup.exe` from the current Office Deployment Tool at the root before running
the Win32 Content Prep Tool. No source files. Learn notes that adding Project to an
existing Office installation pulls under 50 MB from the CDN, because the shared
Office components are already on the device.

## Intune app configuration

| Setting | Value |
| --- | --- |
| Install command | `setup.exe /configure install-M365-Project.xml` |
| Uninstall command | `setup.exe /configure uninstall-M365-Project.xml` |
| Install behavior | System |
| Device restart behavior | Determine behavior based on return codes |
| Installation time required | 60 minute default is usually adequate for an add-on. Maximum 1440 minutes. |
| Allow available uninstall | Yes |
| Detection rule type | Use a custom detection script |
| Detection script | `Detect-M365Project.ps1` |
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |
| Dependency | `M365-Base` or `M365-Base-Business`, with Automatically install set to No |
| Assignment intent | **Available for enrolled devices**, assigned to a licensed user group |

Assign to a user group. Project Plan 3 and Plan 5 are per user entitlements, so
availability in Company Portal should follow the licence.

Set the dependency but leave Automatically install as No. `Version="MatchInstalled"`
needs at least one Click-to-Run product already on the device, so without Office
this package has nothing to match. The dependency makes that prerequisite explicit
and reportable instead of surfacing as an opaque install failure. Note from Learn
that a Win32 app with a dependency has its Company Portal uninstall button hidden
even when Allow available uninstall is Yes.

## Validating the package end to end

1. On a device with Microsoft 365 Apps but no Project, run `powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365Project.ps1` then `echo $LASTEXITCODE`. Expect no output and exit code 1.
2. Record the channel from Word, File then Account, and `UpdateChannel` under `HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration`.
3. Run the install command from an elevated prompt.
4. Run the detection script again. Expect one line and exit code 0.
5. Re-read the channel in both places. It must be unchanged. **Run this on a Current Channel device.** A Monthly Enterprise Channel device cannot show you this failure.
6. Open Project and confirm the display language matches Office, including da-dk if the device had it.
7. Run the uninstall command. Confirm Project is gone, Office is still present, and the base detection script still returns exit code 0.
