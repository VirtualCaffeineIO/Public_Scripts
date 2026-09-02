# M365-Lang-da-dk

Danish (Denmark) language pack, `da-dk`, added to an existing Microsoft 365 Apps
installation. Offered in Company Portal as an available install.

## One worked example, running through all three files

The previous version of this package was internally inconsistent. The readme
showed `da-dk`, the XML installed `es-ES` and the detection script checked
`ja-JP`. The result was that it installed Spanish, looked for Japanese, never
found it, and reinstalled Spanish on every evaluation cycle forever.

`da-dk` is the worked example here and it appears identically in all three files:

| File | Culture value |
| --- | --- |
| `install-M365-Lang-da-dk.xml` | `da-dk` |
| `uninstall-M365-Lang-da-dk.xml` | `da-dk` |
| `Detect-M365LangDaDk.ps1` | `da-dk` |

To offer another language, copy the whole folder, rename it, and change the
culture code in all three files together. Culture codes come from the supported
language table on Microsoft Learn. Danish carries companion proofing languages for
Danish, English, German and Swedish, so users needing Danish spell check only may
not need the full pack at all.

## Worked example estate

| Property | Value used here | Where to change it |
| --- | --- | --- |
| Base language | en-us, installed by the base package | not set here |
| Requestable extra | da-dk | all three files in this folder |
| Update channel | inherited from the device, not set | intentionally absent from the XML |
| Architecture | inherited from the device, not set | intentionally absent from the XML |
| Version | `MatchInstalled` | `Version` in the install XML |
| Product ID | `LanguagePack` | `Product ID` in the XML |

## Why no `Channel` and no `OfficeClientEdition`

Same reasoning as the Visio and Project add-ons. Per the ODT reference on Learn,
when Microsoft 365 Apps is already installed and `Channel` is not specified the
ODT matches the channel of the existing installation, and the same applies to
architecture. A language request must not re-channel a device's Office.

`Version="MatchInstalled"` pins the language pack to the build already on the
device. Without it, the ODT installs the latest available build and drags the
whole installation forward because a user asked for Danish. That was the missing
attribute in the old package.

The same documentation contradiction applies here as in the add-on packages: the
ODT configuration reference says `Channel` is required alongside
`Version="MatchInstalled"`, while the Microsoft 365 Apps Rangers best practices
page gives a language pack configuration as one of its worked examples and omits
`Channel` deliberately. This package follows the best practices page. Validate on
a device that is not on Monthly Enterprise Channel before broad release.

## Why there is no `TargetProduct="All"`, which contradicts a common assumption

This deserves a direct answer, because the request that produced this package
asked for `TargetProduct="All"` to be added and the documentation does not
support it.

`TargetProduct` is an attribute of the `Language` element. Per the ODT
configuration reference it is only meaningful "When using MatchInstalled",
meaning when the `Language ID` itself is `MatchInstalled`. It answers one
question: which already installed product's language list should be copied. In
this package the `Language ID` is the literal value `da-dk`, because the entire
purpose of the package is to install one specific language the device does not
have. There is nothing to match, so `TargetProduct` has no effect.

The best practices page shows exactly this shape for a language pack: `Add
Version="MatchInstalled"`, `Product ID="LanguagePack"`, and a literal `Language
ID`. No `TargetProduct`.

`TargetProduct="All"` belongs in the Visio and Project packages, where the
`Language ID` genuinely is `MatchInstalled` and the add-on needs to inherit
whatever languages the base already has. Both of those packages use it. This one
correctly does not.

There is also a reason to actively avoid adding it here. The ExcludeApp section
of the ODT reference states that when a configuration file used against an
existing install lists all the languages already on the device, its ExcludeApp
setting **overrides** the previous ExcludeApp settings, and when it does not list
them all, the two are **combined**. Adding
`<Language ID="MatchInstalled" TargetProduct="All" />` here would enumerate every
installed language, and this file declares no ExcludeApp elements. The override
path is the one that would apply, which risks reinstating applications the base
package deliberately excluded, new Outlook among them. A language request must
not quietly undo an application exclusion decision.

This is reasoning from the documented override rule rather than an observed test
result, and it is presented as such. Either way it argues for leaving the
attribute out, which is also what the documented example does.

The real defect in the old package was the missing `Version="MatchInstalled"`,
and that is fixed. See MIGRATION.md, defect 3.

## Files

| File | Purpose |
| --- | --- |
| `install-M365-Lang-da-dk.xml` | ODT configuration for install |
| `uninstall-M365-Lang-da-dk.xml` | ODT configuration for removal |
| `Detect-M365LangDaDk.ps1` | Intune custom detection script |

Add `setup.exe` from the current Office Deployment Tool at the root before running
the Win32 Content Prep Tool. No source files. Learn notes a full language pack is
roughly 200 to 300 MB from the CDN, against 30 to 50 MB for proofing tools alone.
If your users only need Danish spell check, build a `ProofingTools` package
instead by changing the `Product ID`.

One important constraint from Learn: `MatchInstalled` cannot be used with the ODT
`/download` switch, and it requires at least one Click-to-Run product to already
be installed. This package is install only, which is correct for a language pack
that by definition adds to an existing install.

## Intune app configuration

| Setting | Value |
| --- | --- |
| Install command | `setup.exe /configure install-M365-Lang-da-dk.xml` |
| Uninstall command | `setup.exe /configure uninstall-M365-Lang-da-dk.xml` |
| Install behavior | System |
| Device restart behavior | Determine behavior based on return codes |
| Installation time required | 60 minute default is usually adequate. Maximum 1440 minutes. |
| Allow available uninstall | Yes |
| Detection rule type | Use a custom detection script |
| Detection script | `Detect-M365LangDaDk.ps1` |
| Run script as 32-bit process on 64-bit clients | No |
| Enforce script signature check | No |
| Dependency | `M365-Base` or `M365-Base-Business`, with Automatically install set to No |
| Assignment intent | **Available for enrolled devices**, assigned to a user group |

Assign to a user group. Language is a user need, not a device attribute, and
Company Portal availability should follow the person.

The dependency exists because `Version="MatchInstalled"` requires an existing
Click-to-Run product. Leave Automatically install as No so a device without Office
reports an unmet dependency rather than silently pulling a full Office install.

An alternative worth knowing about: Learn documents a policy setting, "Allow users
who aren't admins to install language accessory packs", available through Group
Policy or Cloud Policy, which lets users add a display language from inside an
Office app without local admin rights. If that fits your estate, you may not need
this package at all. It does not work when programmatic control of Microsoft 365
Apps updates is enabled.

## Detection, and an honest caveat

Microsoft Learn documents the key
`HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` and names
`UpdateChannel`, `CDNBaseUrl`, `UpdateUrl` and `UnmanagedUpdateURL` under it. Learn
does **not** document any registry value that lists installed Office language
packs, under that key or anywhere else.

The detection script therefore checks two locations that are observed behaviour
rather than a documented contract: string values under the Click-to-Run
configuration key, and `InstalledUIs` under
`HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\LanguageResources`. Either hit counts
as detected.

Install `da-dk` by hand on one reference device and read both locations before you
deploy this. Confirm which one your build populates and in what form, then keep or
replace the logic accordingly. This is the least certain part of the package set
and it is called out rather than papered over.

## Validating the package end to end

1. On a device with Microsoft 365 Apps in en-us and no Danish, run `powershell.exe -ExecutionPolicy Bypass -File .\Detect-M365LangDaDk.ps1` then `echo $LASTEXITCODE`. Expect no output and exit code 1.
2. Record the channel from Word, File then Account, and record the current build number.
3. Run the install command from an elevated prompt.
4. Run the detection script again. Expect one line and exit code 0.
5. Re-read the channel and the build number. Both must be unchanged. The build number check is the test for the missing `Version="MatchInstalled"`.
6. Open Word, go to File, Options, Language, and confirm Danish is present as a display language.
7. Confirm the base package's application exclusions survived. On the worked estate, confirm new Outlook was not installed by this operation.
8. Run the uninstall command. Confirm Danish is gone, English remains, and the base detection script still returns exit code 0.

Steps 5 and 7 are the ones that catch the failures this rebuild exists to fix.
