# M365-Base

Microsoft 365 Apps for enterprise. Required install on every managed Windows device.

## Worked example estate

Everything in this folder is written for one specific estate. Read this list first
and substitute your own values wherever they differ.

| Property | Value used here | Where to change it |
| --- | --- | --- |
| Update channel | Monthly Enterprise Channel | `Channel` in `install-M365-Base.xml` |
| Architecture | 64-bit | `OfficeClientEdition` in the XML, `$ExpectedPlatform` in the detection script |
| Base language | en-us | `Language ID` in `install-M365-Base.xml` |
| Requestable extra language | da-dk | separate package, `M365-Lang-da-dk` |
| Product ID | `O365ProPlusRetail` | XML and `$ExpectedProductId`, and they must always agree |
| Source | Office CDN, no embedded source files | omit or set `SourcePath` |

## Product ID, read this before you deploy

Microsoft Learn lists the product IDs supported by the Office Deployment Tool and
then maps plan names to them. That mapping is not the one most people assume.

- Office 365 E3, Office 365 E5, Microsoft 365 E3 and Microsoft 365 E5 map to `O365ProPlusRetail`.
- The plan literally named **Microsoft 365 Apps for enterprise** maps to `O365ProPlusEEANoTeamsRetail`.
- Every "(no Teams)" enterprise plan also maps to `O365ProPlusEEANoTeamsRetail`.

This package ships `O365ProPlusRetail` because the worked estate is licensed
through Microsoft 365 E3. If your tenant holds the standalone Apps for enterprise
plan, change both the XML and the detection script. Learn is explicit that the
wrong product ID installs but does not activate.

## Files

| File | Purpose |
| --- | --- |
| `install-M365-Base.xml` | ODT configuration for install |
| `uninstall-M365-Base.xml` | ODT configuration for removal |
| `Detect-M365Base.ps1` | Intune custom detection script |

The package you upload must also contain `setup.exe` from the Office Deployment
Tool, at the root of the folder you pass to the Win32 Content Prep Tool. Download
the current ODT from the Microsoft Download Center. No ODT version number is
pinned anywhere in this package, because pinning a version this repository has not
verified would be a fabricated claim. Use the current release.

The package carries no Office source files. The ODT pulls what it needs from the
Office CDN at install time, so the `.intunewin` stays small and never goes stale.

## Intune app configuration

Create as **Apps** > **All apps** > **Create** > **Windows** > **Windows app (Win32)**.

| Setting | Value |
| --- | --- |
| Install command | `setup.exe /configure install-M365-Base.xml` |
| Uninstall command | `setup.exe /configure uninstall-M365-Base.xml` |
| Install behavior | System |
| Device restart behavior | Determine behavior based on return codes |
| Installation time required | Raise it above the 60 minute default. A first install pulling roughly 3 GB from the CDN over a constrained link can exceed 60 minutes, and Intune fails the install when the timer expires. The maximum accepted value is 1440 minutes. |
| Allow available uninstall | No |
| Detection rule type | Use a custom detection script |
| Detection script | `Detect-M365Base.ps1` |
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |
| Requirement, OS architecture | 64-bit |
| Assignment intent | **Required**, assigned to a device group |

Assign to devices, not users. Office is a device level install, the Click-to-Run
configuration key is machine scope, and a user targeted Win32 app that needs
admin rights fails on a standard user.

### Autopilot and the Enrollment Status Page

Deploy Microsoft 365 Apps as a **Win32** app, not with the built in
**Microsoft 365 Apps (Windows 10 and later)** app type, whenever the ESP tracks
the install. This is Microsoft's own documented recommendation and the reason is
specific rather than stylistic: the built in app type is not installed by the
Intune Management Extension, so it can begin installing while the IME is midway
through a tracked Win32 install. That concurrency hangs the ESP and fails the
deployment.

If you never track Office during ESP, the built in app type is a legitimate
choice and needs no packaging. The Win32 route exists to buy you ESP
determinism, dependency and supersedence relationships, and a detection rule you
control. It is not inherently better and this repository does not claim it is.

## Application decisions made in the install XML

Each of these is a decision recorded on purpose. The XML carries the same
reasoning inline.

**Skype for Business is excluded.** The ExcludeApp ID is `Lync`, not `Skype`.
Skype for Business is still installed with new installations of Microsoft 365
Apps unless excluded.

**New Outlook for Windows is excluded.** The ExcludeApp ID is
`OutlookForWindows`, which refers to the new Outlook app and is distinct from
`Outlook`, which is classic Outlook. Excluding `OutlookForWindows` leaves classic
Outlook installed. The decision is explicit because moving to new Outlook is a
mail client migration with its own add-in compatibility work and its own rollback
plan. It should happen on a date somebody chose, not as a side effect of an Office
reinstall. If your estate has already migrated, delete the line.

**Neither `Groove` nor `OneDrive` is excluded.** See MIGRATION.md, defect 5. The
short version: Learn lists both as valid IDs and then says to use `Groove` for
OneDrive, while other Microsoft pages use each ID for a different thing. An
ambiguity like that does not belong in a package that lands on every device.

**Teams is not excluded.** Teams ships with new and existing Microsoft 365 Apps
installations on Windows where a Teams service plan is present. The new Teams
client is not included in the Microsoft 365 Apps offline package, so the device
needs internet access during install to acquire it. This package installs from
the CDN, so that condition is already satisfied. To suppress Teams, add
`<ExcludeApp ID="Teams" />`, but be aware an Online Repair can bring it back. The
durable controls are the Group Policy setting or Modern Apps Settings in the
Microsoft 365 Apps admin center.

## OEM and consumer Office removal

The install XML carries a `Remove` block naming consumer Click-to-Run product IDs
that ship preinstalled on OEM hardware, plus `<RemoveMSI />` for Windows Installer
era Office. `RemoveMSI` only handles MSI based Office. Click-to-Run consumer builds
have to be named explicitly, which is what the `Remove` block does.

The detection script does not read that list. It tests for one thing: is
`O365ProPlusRetail` present, at the expected architecture. That is deliberate.
See MIGRATION.md, defect 4.

## Validating the package end to end

1. On a clean reference device, confirm `HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` does not exist.
2. Run the detection script by hand: `powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365Base.ps1`, then `echo $LASTEXITCODE`. Expect no output and exit code 1.
3. Run the install command from an elevated prompt in the package folder.
4. Read `ProductReleaseIds` and `Platform` under the Click-to-Run configuration key. Confirm the product ID matches `$ExpectedProductId` and the platform matches `$ExpectedPlatform`.
5. Run the detection script again. Expect one line of output and exit code 0. This is the step the old package failed.
6. Open Word, go to File then Account, and confirm the channel reads as expected.
7. Run the uninstall command, then run the detection script once more. Expect no output and exit code 1.

Step 5 is the whole point. A detection script that produces exit code 0 with no
output passes a casual eyeball test and still reinstalls Office on every device
in the estate, every day.
