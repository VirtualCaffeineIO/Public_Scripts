# M365-Visio

Visio desktop app, from a Visio Plan 2 subscription. Add-on to an existing
Microsoft 365 Apps installation. Offered in Company Portal as an available
install.

## Worked example estate

| Property | Value used here | Where to change it |
| --- | --- | --- |
| Update channel | inherited from the device, not set | intentionally absent from the XML |
| Architecture | inherited from the device, not set | intentionally absent from the XML |
| Base language | inherited via `MatchInstalled` | `TargetProduct` in the XML |
| Requestable extra language | da-dk, inherited automatically | nothing to change |
| Product ID | `VisioProRetail` | XML and `$ExpectedProductId`, and they must agree |
| Version | `MatchInstalled` | `Version` in the XML |

The base estate this was written against runs Monthly Enterprise Channel, 64-bit,
en-us, with da-dk available on request. This package does not depend on any of
that. It reads what is on the device and matches it. That is the point.

## The channel trap this package exists to avoid

The previous version of this package hard-coded `Channel="MonthlyEnterprise"` and
set no `Version`. Installing Visio on a Current Channel device did not throw an
error. It re-channelled that device's entire Office installation, and the switch
took effect at the next update cycle rather than during the install, so the
symptom appeared days later with no obvious cause.

Per the ODT reference on Microsoft Learn, when Microsoft 365 Apps is already
installed and `Channel` is not specified, the ODT matches the channel of the
existing installation. Likewise for `OfficeClientEdition` and architecture. So
this package specifies neither, and one file serves every channel and both
architectures in the estate.

### A contradiction in the documentation you should be aware of

Two Learn pages disagree:

- The ODT configuration reference states: "When you use `Version="MatchInstalled"`, the Channel attribute is required."
- The Microsoft 365 Apps Rangers best practices page, "Build dynamic, lean, and universal packages for Microsoft 365 Apps", uses this exact scenario as its worked example and shows `Version="MatchInstalled"` with **no** `Channel` attribute, explaining that omitting `Channel` is what makes the package universal across update channels.

This package follows the best practices page, because it addresses this precise
scenario and because supplying `Channel` is the thing that causes the harm. It is
still a contradiction in first party documentation and this repository is not
going to pretend otherwise. Validate on a device that is **not** on Monthly
Enterprise Channel before broad release. That test settles it for your estate.

## Language behaviour

`<Language ID="MatchInstalled" TargetProduct="All" />` installs Visio in the same
languages already present across every installed product on the device. A user who
has da-dk on their Office gets da-dk on their Visio without asking twice.

`TargetProduct="All"` rather than a specific product ID is deliberate, so this one
file works whether the base is `O365ProPlusRetail` or `O365BusinessRetail`.

Note a real constraint from Learn: Microsoft 365 Apps supports some languages that
Visio and Project do not, specifically English (United Kingdom), French (Canada)
and Spanish (Mexico). Project supports the same set Visio does. If those base
languages exist in your estate, test this package against one of those devices
before broad release.

## Files

| File | Purpose |
| --- | --- |
| `install-M365-Visio.xml` | ODT configuration for install |
| `uninstall-M365-Visio.xml` | ODT configuration for removal |
| `Detect-M365Visio.ps1` | Intune custom detection script |

Add `setup.exe` from the current Office Deployment Tool at the root before running
the Win32 Content Prep Tool. No source files. Learn notes that a lean add-on
package like this pulls roughly 100 to 200 MB from the CDN for Visio depending on
language count, against roughly 3 GB for a package with embedded source files.

## Intune app configuration

| Setting | Value |
| --- | --- |
| Install command | `setup.exe /configure install-M365-Visio.xml` |
| Uninstall command | `setup.exe /configure uninstall-M365-Visio.xml` |
| Install behavior | System |
| Device restart behavior | Determine behavior based on return codes |
| Installation time required | 60 minute default is usually adequate for an add-on. Raise it on constrained links. Maximum 1440 minutes. |
| Allow available uninstall | Yes |
| Detection rule type | Use a custom detection script |
| Detection script | `Detect-M365Visio.ps1` |
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |
| Dependency | `M365-Base` or `M365-Base-Business`, with Automatically install set to No |
| Assignment intent | **Available for enrolled devices**, assigned to a licensed user group |

Two things worth being deliberate about.

**Assign to a user group, not a device group.** Visio Plan 2 is a per user
entitlement. Availability in Company Portal should follow the licence.

**Set the dependency, but do not let it auto install.** `Version="MatchInstalled"`
requires at least one Click-to-Run product already on the device. Without Office,
this package has nothing to match and the install fails. A dependency makes that
prerequisite explicit and reportable. Setting Automatically install to No means a
device with no Office reports the dependency as unmet rather than silently pulling
a 3 GB Office install because someone clicked Install on Visio.

Note from Learn: if a Win32 app has a dependency, Company Portal hides the
uninstall button even when Allow available uninstall is Yes. If a user driven
uninstall matters to you more than the dependency guard, drop the dependency and
accept that a device without Office will report an install failure instead.

## Validating the package end to end

1. On a device with Microsoft 365 Apps installed but no Visio, run `powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365Visio.ps1` then `echo $LASTEXITCODE`. Expect no output and exit code 1.
2. Record the current channel from Word, File then Account. Also record `UpdateChannel` under `HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration`.
3. Run the install command from an elevated prompt.
4. Run the detection script again. Expect one line and exit code 0.
5. Re-read the channel in both places. It must be unchanged. **This is the test for defect 2.** Run it on a Current Channel device specifically, not only on Monthly Enterprise Channel, because a Monthly Enterprise device cannot show you the failure.
6. Open Visio and confirm the display language matches Office, including da-dk if the device had it.
7. Run the uninstall command. Confirm Visio is gone, Office is still present, and the base detection script still returns exit code 0.

Step 5 on a Current Channel device is the one that matters. Every other step
passed on the old package too.
