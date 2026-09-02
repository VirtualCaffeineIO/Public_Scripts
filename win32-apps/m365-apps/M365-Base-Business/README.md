# M365-Base-Business

Microsoft 365 Apps for business. Required install on devices licensed through a
Microsoft 365 business plan.

## Why this package exists

The previous package set had no Apps for business variant. Every device got the
enterprise product ID. On a business licence that install completes, licensing
then reconciles the device against the entitlement it actually holds, and the
product recorded on the device no longer matches the product ID the detection
script looks for. Detection reports not installed, Intune reinstalls, and the
device never settles. See MIGRATION.md, defect 7.

Microsoft Learn maps Microsoft 365 Business Standard and Microsoft 365 Business
Premium to `O365BusinessRetail`, and states that the wrong product ID means Office
cannot activate. Two product IDs need two packages, two detection scripts and two
assignment groups. Assign this one and `M365-Base` to mutually exclusive groups.

## Worked example estate

| Property | Value used here | Where to change it |
| --- | --- | --- |
| Update channel | Monthly Enterprise Channel | `Channel` in `install-M365-Base-Business.xml` |
| Architecture | 64-bit | `OfficeClientEdition` in the XML, `$ExpectedPlatform` in the script |
| Base language | en-us | `Language ID` in the XML |
| Requestable extra language | da-dk | separate package, `M365-Lang-da-dk` |
| Product ID | `O365BusinessRetail` | XML and `$ExpectedProductId`, and they must agree |
| Source | Office CDN, no embedded source files | omit or set `SourcePath` |

If the tenant holds Microsoft 365 Business Standard (no Teams) or Microsoft 365
Business Premium (no Teams), Learn maps those plans to
`O365BusinessEEANoTeamsRetail`. Change the XML and the detection script together.

## Files

| File | Purpose |
| --- | --- |
| `install-M365-Base-Business.xml` | ODT configuration for install |
| `uninstall-M365-Base-Business.xml` | ODT configuration for removal |
| `Detect-M365BaseBusiness.ps1` | Intune custom detection script |

Add `setup.exe` from the current Office Deployment Tool at the root of the folder
before running the Win32 Content Prep Tool. No source files are included. The ODT
pulls from the Office CDN at install time.

## Intune app configuration

| Setting | Value |
| --- | --- |
| Install command | `setup.exe /configure install-M365-Base-Business.xml` |
| Uninstall command | `setup.exe /configure uninstall-M365-Base-Business.xml` |
| Install behavior | System |
| Device restart behavior | Determine behavior based on return codes |
| Installation time required | Raise it above the 60 minute default. Maximum is 1440 minutes. |
| Allow available uninstall | No |
| Detection rule type | Use a custom detection script |
| Detection script | `Detect-M365BaseBusiness.ps1` |
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |
| Requirement, OS architecture | 64-bit |
| Assignment intent | **Required**, assigned to a device group |

Assign to devices. The Click-to-Run configuration key is machine scope, and a
user targeted Win32 app that needs admin rights fails on a standard user.

The Autopilot and ESP guidance in `M365-Base/README.md` applies here without
change: track this as a Win32 app, not the built in Microsoft 365 Apps app type.

## A note on the Intune built in app type and business licensing

If you use the built in **Microsoft 365 Apps (Windows 10 and later)** app type
rather than Win32 packaging, Learn notes that the Apps for business edition is
supported but has to be configured through the XML data option rather than the
graphical app suite picker. That is worth knowing when comparing the two routes.
It does not change the recommendation here.

## Application decisions

Identical to `M365-Base`. Skype for Business excluded via `Lync`. New Outlook
excluded via `OutlookForWindows`, deliberately and reversibly. Neither `Groove`
nor `OneDrive` excluded. Teams not excluded. The reasoning is written out in
`M365-Base/README.md` and inline in the XML.

## Validating the package end to end

1. On a clean reference device holding a business licence, confirm `HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` does not exist.
2. Run `powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365BaseBusiness.ps1` then `echo $LASTEXITCODE`. Expect no output and exit code 1.
3. Run the install command from an elevated prompt in the package folder.
4. Read `ProductReleaseIds` under the Click-to-Run configuration key and confirm it contains `O365BusinessRetail`.
5. Run the detection script again. Expect one line and exit code 0.
6. Sign in to an Office app and confirm it activates. This is the step that catches a product ID and licence mismatch, and it is the reason this package exists.
7. Run the uninstall command, then the detection script. Expect no output and exit code 1.
