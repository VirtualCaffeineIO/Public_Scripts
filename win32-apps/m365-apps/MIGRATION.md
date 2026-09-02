# MIGRATION.md

Rebuild of the Microsoft 365 Apps deployment packages. This set replaces two
defective trees. Every defect below was present in the old packages, every one is
fixed here, and every load bearing claim carries the Microsoft Learn page it came
from. The full URL list is at the end.

Everything was verified against Microsoft Learn at the time of writing rather than
from memory. Where Learn is ambiguous or contradicts itself, this document says
so instead of resolving it by guess. Where something could not be verified at all,
it says that too.

## What is in this set

| Folder | Product | Assignment |
| --- | --- | --- |
| `M365-Base` | Microsoft 365 Apps for enterprise | Required, device group |
| `M365-Base-Business` | Microsoft 365 Apps for business | Required, device group |
| `M365-Visio` | Visio desktop app, Visio Plan 2 | Available for enrolled devices, user group |
| `M365-Project` | Project desktop app, Plan 3 or Plan 5 | Available for enrolled devices, user group |
| `M365-Lang-da-dk` | Danish language pack | Available for enrolled devices, user group |

The worked example estate throughout is Monthly Enterprise Channel, 64-bit, en-us
base language, with da-dk as the requestable extra. Each README states this and
names the exact place to substitute your own values.

## The defects

### 1. Detection scripts exited 0 with no output

**What was wrong.** The old detection scripts exited with code 0 and wrote nothing
to STDOUT. That is not a partial success. It is the documented signal for "not
installed".

Microsoft Learn is explicit: the Intune agent reads the exit code, STDOUT and
STDERR, and "if the exit code is zero and STDOUT has data, the application
detection status is installed". Exit code 0 with an empty STDOUT satisfies half
the condition and therefore fails. Intune re-offers a required app it believes is
missing on roughly a 24 hour cadence, so the effect was a full Office reinstall on
every device, every day, indefinitely.

**What changed.** Every detection script in this set writes exactly one line to
STDOUT and exits 0 on success, and exits 1 in complete silence on every failure
path. The reasoning is written into the header comment of each script rather than
left as folklore.

**A refinement the old package did not account for.** Learn also states that "if
any data is written to STDERR, the detection result is evaluated as not installed,
even if data is written to STDOUT and the script exits with an exit code of zero".
STDERR poisons a detection that is otherwise correct. So every script here sets
`$ErrorActionPreference = 'Stop'`, wraps its body in `try`/`catch`, and the catch
block is deliberately silent. A `Write-Error` in a catch block, which is the
instinctive thing to write, would silently break detection on exactly the devices
where a registry read failed. That is a second, quieter version of the same bug
and it is now designed out.

Source: Add, Assign, and Monitor a Win32 App in Microsoft Intune, Step 4.

### 2. Add-on install XML hard-coded the channel and set no version

**What was wrong.** `M365-Visio` and `M365-Project` hard-coded
`Channel="MonthlyEnterprise"` with no `Version="MatchInstalled"`. Installing Visio
on a Current Channel device did not fail. It re-channelled that device's entire
Office installation, and because the switch is performed at the next update cycle
rather than at install time, the symptom appeared days later with nothing linking
it to the Visio request.

Learn states the mechanism directly, under the `Channel` attribute of the `Add`
element: the value "determines the channel to be installed, regardless of an
optionally specified update channel in the Updates element or via Group Policy
Setting. If there's such a setting with a different update channel, the channel
switch is performed after the installation during the next update cycle."

**What changed.** Both add-on packages and the language pack now omit `Channel`
and `OfficeClientEdition` entirely, and set `Version="MatchInstalled"`. Learn
states that when Microsoft 365 Apps is already installed and `Channel` is not
specified, the ODT matches the channel of the existing installation, and the same
applies to architecture when `OfficeClientEdition` is omitted. One file now serves
every channel and both architectures in the estate.

**A contradiction in Microsoft's own documentation, stated rather than hidden.**
Two Learn pages disagree about this.

- The ODT configuration reference, under the `Version` attribute, says: "When you use `Version="MatchInstalled"`, the Channel attribute is required."
- The Microsoft 365 Apps Rangers best practices page, "Build dynamic, lean, and universal packages for Microsoft 365 Apps", takes adding Project to an existing Office installation as its primary worked example and shows `<Add Version="MatchInstalled">` with **no** `Channel` attribute. It then explains the omission as the point: "We removed the channel for the same reason. ODT will automatically match the already-assigned update channel."

These packages follow the best practices page, on the grounds that it addresses
this precise scenario, second installs onto an existing Office, and that supplying
`Channel` is the thing that causes the harm being fixed. This is a judgement call
between two first party sources, not a settled fact. Each affected README says so
and tells you to validate on a device that is not on Monthly Enterprise Channel
before broad release. A Monthly Enterprise Channel test device cannot show you
this failure, which is very likely how the original defect survived testing.

Sources: Configuration options for the Office Deployment Tool, `Version` and
`Channel` attributes. Build dynamic, lean, and universal packages for Microsoft
365 Apps.

### 3. Language pack XML did not set `TargetProduct="All"` with MatchInstalled

This one needs correcting rather than simply fixing, because the documentation
does not support the change as originally described.

**What the fact-check found.** `TargetProduct` is an attribute of the `Language`
element and, per the ODT configuration reference, it applies "When using
MatchInstalled", meaning when the `Language ID` itself is `MatchInstalled`. Its
job is to say which already installed product's language list should be copied. A
language pack package installs one specific named language the device does not
yet have, so its `Language ID` is the literal culture code and there is nothing
for `TargetProduct` to match. The attribute has no effect there.

The best practices page confirms the intended shape. Its worked language pack
example is `<Add Version="MatchInstalled">`, `<Product ID="LanguagePack">`, and a
literal `<Language ID="de-de" />`. No `TargetProduct`.

**There is also an argument for actively leaving it out.** The ExcludeApp section
of the ODT reference states that when a configuration file used against an
existing install lists all the languages already on the device, its ExcludeApp
setting **overrides** any previous ExcludeApp settings, and when it does not list
them all, the two are **combined**. Adding
`<Language ID="MatchInstalled" TargetProduct="All" />` to the language pack file
would enumerate every installed language, and that file declares no ExcludeApp
elements. The override path is the one that would apply, which risks reinstating
applications the base package deliberately excluded, new Outlook among them. A
language request should not quietly undo an application exclusion decision. This
is reasoning from the documented override rule, not an observed test result, and
it is labelled as such in the package README.

**What the real defect was, and what changed.** The genuine fault in the old
language pack XML was the missing `Version="MatchInstalled"`. Without it the ODT
installs the latest available build, so a user asking for Danish could drag the
whole Office installation forward to a build the change process had not approved.
`Version="MatchInstalled"` is now set, and `Channel` and `OfficeClientEdition` are
omitted for the reasons in defect 2.

`TargetProduct="All"` **is** used, correctly, in `M365-Visio` and `M365-Project`.
Those packages genuinely do use `Language ID="MatchInstalled"`, and `All` rather
than a specific product ID is what lets one file serve both the enterprise and the
business base.

Sources: Configuration options for the Office Deployment Tool, `TargetProduct` and
`ExcludeApp`. Overview of deploying languages for Microsoft 365 Apps. Build
dynamic, lean, and universal packages for Microsoft 365 Apps.

### 4. The base detection SKU list and the XML `Remove` block disagreed

**What was wrong.** Two lists of product IDs existed, one in the detection script
and one in the install XML's `Remove` block, and they had drifted apart. On OEM
hardware carrying a preinstalled consumer Office, the two lists produced
contradictory answers about the same device: the install would run, the detection
would still say not installed, and Intune would install again. A detect then
install loop with no terminating condition.

**What changed.** There is now only one list, and the detection script does not
consult it.

The `Remove` block in each base install XML names OEM and consumer Click-to-Run
product IDs, every one of them drawn from the supported product ID list on Learn:
`O365HomePremRetail`, `HomeStudent2021Retail`, `Home2024Retail`,
`HomeBusiness2021Retail`, `HomeBusiness2024Retail`, `Personal2021Retail` and
`OneNoteFreeRetail`. `<RemoveMSI />` handles Windows Installer era Office
separately, because Learn is clear that `RemoveMSI` does not touch Click-to-Run
installs, which have to be named explicitly through `Remove`.

The detection script tests one thing: is the product ID this package installs
present, at the expected architecture. It never reads the removal list. Two lists
cannot disagree when the second list does not exist, so this class of loop is
designed out rather than patched.

**One thing worth flagging.** This set places `Add` and `Remove` in the same
configuration file. Learn documents both elements and documents combining `Add`
with `RemoveMSI`, but this repository did not find a Learn example that combines
`Add` with `Remove` in a single file. It is stated here rather than presented as
settled. If your validation shows the ODT ignoring one of the two in a single
pass, split the removal into a separate configuration file run before the install.
That changes the packaging, not the design.

Sources: Product IDs supported by the Office Deployment Tool for Click-to-Run.
Configuration options for the Office Deployment Tool, `Remove` element. Remove
existing MSI versions of Office when upgrading to Microsoft 365 Apps.

### 5. `<ExcludeApp ID="Groove" />` shipped an estate-wide OneDrive exclusion

**What was wrong.** The old base XML excluded `Groove`. On the reading Microsoft's
own ODT reference gives, that is how OneDrive is excluded, so this shipped a
OneDrive exclusion to every device in the estate, taking Known Folder Move with it
since KFM depends on the sync client.

**What changed.** Neither `Groove` nor `OneDrive` appears in any XML in this set.
Both base packages carry an inline comment explaining the omission so nobody
reinstates it by tidying.

**What the documentation actually says, exactly, because this is genuinely
ambiguous and the request asked for it unresolved rather than guessed at.**

The ODT configuration reference lists twelve allowed `ExcludeApp` ID values, and
`Groove` and `OneDrive` are **both** on that list as separate entries:

`Access`, `Excel`, `Groove`, `Lync`, `OneDrive`, `OneNote`, `Outlook`,
`OutlookForWindows`, `PowerPoint`, `Publisher`, `Teams`, `Word`.

Immediately below that list, the same page carries the note: "For OneDrive, use
**Groove**. For Skype for Business, use **Lync**."

Those two statements do not sit together. If `OneDrive` is a valid ID in its own
right, the instruction to use `Groove` for OneDrive is at best redundant and at
worst wrong. And Microsoft uses each form elsewhere, for different things:

- The ODT overview page, under "Exclude OneDrive when installing Microsoft 365 Apps or other applications", gives a worked configuration file whose exclusion line is `<ExcludeApp ID="OneDrive" />`.
- The SharePoint page "Control Groove.exe installation when deploying Office using Click-to-Run" gives `<ExcludeApp ID="Groove" />` as the way to stop **Groove.exe**, which that page defines as the *previous* OneDrive for Business sync app, distinct from "the new OneDrive sync app (OneDrive.exe)". It also records that support for Groove.exe ended on 11 January 2021 and that it stopped syncing Microsoft 365 content on 1 February 2021.

So there is a defensible historical reading in which `Groove` targets the retired
Groove.exe sync app and `OneDrive` targets the current OneDrive.exe client, and
the note on the ODT reference is stale guidance from the era when those were the
same product. This repository does **not** assert that reading as fact. What is
verified is that both IDs are listed as valid, that the note says to use `Groove`
for OneDrive, and that two Microsoft pages use the two IDs differently.

The operational conclusion does not depend on resolving it. An ambiguity with this
blast radius has no place in a package that lands on every device in the estate.
If you have a genuine requirement to suppress OneDrive, do it in a narrowly scoped
package, and test the result on a reference device, checking both the sync client
and Known Folder Move, before it goes anywhere near production.

Sources: Configuration options for the Office Deployment Tool, `ExcludeApp`
element. Overview of the Office Deployment Tool. Control Groove.exe installation
when deploying Office using Click-to-Run.

### 6. `<ExcludeApp ID="Bing" />`, which is not a valid value

**What was wrong.** The old base XML contained `<ExcludeApp ID="Bing" />`. `Bing`
is not one of the twelve allowed `ExcludeApp` ID values. Confirmed: the complete
list is `Access`, `Excel`, `Groove`, `Lync`, `OneDrive`, `OneNote`, `Outlook`,
`OutlookForWindows`, `PowerPoint`, `Publisher`, `Teams`, `Word`. There is no
`Bing`.

**What changed.** Removed. It appears in no file in this set.

Whatever the intent was, an invalid `ExcludeApp` ID does not achieve it, and it
sits in the XML looking like a control that exists. If the goal was to suppress a
Bing search extension, that is not an ODT `ExcludeApp` concern and needs to be
handled wherever that component is actually installed from.

Source: Configuration options for the Office Deployment Tool, `ExcludeApp`
element, ID attribute.

### 7. No Apps-for-business variant existed

**What was wrong.** Every device got the enterprise product ID regardless of
licence. On a Microsoft 365 business licence the install completes, licensing then
reconciles the device against the entitlement it actually holds, and the product
recorded on the device stops matching the product ID the detection script looks
for. Detection flips to not installed and the reinstall loop closes.

Learn maps Microsoft 365 Business Standard and Microsoft 365 Business Premium to
`O365BusinessRetail`, and states plainly: "If you use the wrong product ID, you
can't activate Office."

**What changed.** `M365-Base-Business` is a full sibling of `M365-Base`, with its
own install XML, uninstall XML, detection script and README. Its detection script
looks for `O365BusinessRetail` and nothing else, so a device holding the wrong
product for its licence shows up in Intune as not installed rather than passing a
detection that covers both IDs. Assign the two packages to mutually exclusive
groups.

**A refinement from the fact-check that is worth knowing.** The Learn plan to
product ID mapping is not the one most people assume from the plan names:

| Plan | Product ID per Learn |
| --- | --- |
| Office 365 E3, Office 365 E5, Microsoft 365 E3, Microsoft 365 E5 | `O365ProPlusRetail` |
| **Microsoft 365 Apps for enterprise** | `O365ProPlusEEANoTeamsRetail` |
| Microsoft 365 Business Standard, Microsoft 365 Business Premium | `O365BusinessRetail` |
| **Microsoft 365 Apps for business** | `O365BusinessEEANoTeamsRetail` |
| Every "(no Teams)" enterprise plan | `O365ProPlusEEANoTeamsRetail` |
| Every "(no Teams)" business plan | `O365BusinessEEANoTeamsRetail` |

The plans literally named "Microsoft 365 Apps for enterprise" and "Microsoft 365
Apps for business" map to the `EEANoTeams` product IDs, not to `O365ProPlusRetail`
and `O365BusinessRetail`. These packages ship `O365ProPlusRetail` and
`O365BusinessRetail`, because the worked estate is licensed through Microsoft 365
E3 and Business Premium. Check the plan table against your own tenant before you
deploy. Both READMEs carry this warning.

Source: Product IDs supported by the Office Deployment Tool for Click-to-Run.

### 8. The language pack folder's three artifacts disagreed with each other

**What was wrong.** The readme showed `da-dk`, the XML installed `es-ES` and the
detection script checked `ja-JP`. The package installed Spanish, looked for
Japanese, never found it, and reinstalled Spanish on every evaluation cycle.

**What changed.** `da-dk` runs identically through all three files, and each file
says so and names the other two. The README carries a table of the three files and
their culture value, and instructs anyone offering another language to copy the
whole folder and change all three together rather than editing one in place.

The uninstall XML follows the documented `Remove` example for language packs,
naming both `Product ID="LanguagePack"` and the specific `Language ID="da-dk"`, so
removing Danish does not strip every other language from the device.

Source: Overview of deploying languages for Microsoft 365 Apps, "Remove languages
packs or proofing tools".

## Cross cutting decisions this rebuild also made

### New Outlook is now an explicit decision, not silence

`OutlookForWindows` is a valid `ExcludeApp` ID and, per Learn, "refers to the new
Outlook app". It is distinct from `Outlook`, which is classic Outlook.

Both base packages exclude `OutlookForWindows`, deliberately, with the reasoning
written inline. Moving to new Outlook is a mail client migration carrying add-in
compatibility work, user communications and a rollback plan. It should land on a
date somebody chose, not as a side effect of an Office reinstall. Estates that have
already migrated delete one line. Estates that have not keep control of the timing.

The point is that the XML now records a decision either way, instead of leaving
the reader unable to tell whether the absence of an exclusion was a choice.

### Teams, accurately

Teams is included with new and existing installations of Microsoft 365 Apps on
Windows, and since 23 October 2023 new installations include Teams only where a
Teams service plan is in place. `Teams` is a valid `ExcludeApp` ID.

The detail that matters for packaging: **the new Teams client is not bundled in
the Microsoft 365 Apps offline package.** Learn states that for new installations
an active internet connection is required to download the new Teams app, and that
where no connection is available during install, admins have to deploy the new
Teams client separately. These packages install from the Office CDN and carry no
embedded source files, so that condition is already satisfied. An estate that
packages Office with local source files should know it does not get new Teams from
those files.

Teams is not excluded in either base package. If you exclude it, note that an
Online Repair can reinstall it, so the durable controls are the Group Policy
setting or Modern Apps Settings in the Microsoft 365 Apps admin center rather than
the XML alone.

Source: Deploy Microsoft Teams with Microsoft 365 Apps.

### Win32 packaging against the built in Microsoft 365 Apps app type

Microsoft does not blanket-recommend Win32 ODT packaging over the built in app
type. The documented recommendation is conditional and the condition is the
Enrollment Status Page.

Learn, on adding Microsoft 365 Apps in Intune: "If devices are provisioned using
Windows Autopilot and you intend to deploy Microsoft 365 Apps as a tracked app
during the enrollment status page (ESP) process, we recommend deploying Microsoft
365 Apps as a Win32 app. Unlike Win32 apps in Intune, the installation of the
Microsoft 365 Apps app type isn't managed by the Intune Management Extension
(IME). Installing a Microsoft 365 Apps app during ESP can create an installation
concurrency issue, where the Microsoft 365 Apps app begins installing while
there's an ongoing installation of a Win32 app (also tracked during ESP), which
causes the ESP to fail."

The ESP setup page states the same conclusion from the other direction: "To
prevent the ESP from hanging during installation and causing a failed deployment,
we recommend deploying Microsoft 365 Apps with Microsoft Intune by using the Win32
app type."

So the reason is ESP install concurrency, and it is a real documented failure
mode, not a preference. If you never track Office during ESP, the built in app
type is a legitimate choice that needs no packaging at all. This set exists
because ESP determinism, dependency and supersedence relationships, and a
detection rule you control are worth the packaging cost in this estate. It is not
inherently better and these packages do not claim it is.

One related warning from the same page, worth carrying over: when configuring
Microsoft 365 Apps settings through the Intune settings catalog, make sure they do
not conflict with settings in the app deployment, update channel and version in
particular, because Learn notes those conflicts can lead to unexpected behaviour
including app reinstallation.

Sources: Add Microsoft 365 Apps to Windows Devices Using Microsoft Intune. Set up
the Enrollment Status Page.

### Update channels, and the SAEC to Monthly Enterprise unification

Current allowed `Channel` values in both the `Add` and `Updates` elements:
`BetaChannel`, `CurrentPreview`, `Current`, `MonthlyEnterprise`,
`SemiAnnualPreview`, `SemiAnnual`. Older values still work, so existing XML does
not have to be rewritten. Volume licensed Office uses separate values,
`PerpetualVL2019`, `PerpetualVL2021` and `PerpetualVL2024`.

The three primary channels remain Current Channel, Monthly Enterprise Channel and
Semi-Annual Enterprise Channel. The default channel for Microsoft 365 Apps for
enterprise, Microsoft 365 Apps for business, and the subscription Project and Visio
desktop apps is Current Channel. That default is precisely why the base packages
set `Channel` explicitly and the add-ons do not.

On the unification: beginning with the Version 2606 update release in July 2026,
Microsoft unified Semi-Annual Enterprise Channel and Monthly Enterprise Channel
into a single enterprise-focused channel. Devices configured for Semi-Annual
Enterprise Channel receive the same feature and security updates as Monthly
Enterprise Channel devices from Version 2606 onward, and after 2606 or later is
installed they display as Monthly Enterprise Channel in Microsoft 365 Apps
experiences including File then Account.

Three consequences for anyone maintaining these packages:

- `SemiAnnual` remains a valid `Channel` value. The unification changes servicing behaviour and reporting, not the accepted attribute values. No configuration file needs rewriting and Learn states explicitly that no policy migration is required.
- Reporting can disagree with the app. After Version 2606, management tools, dashboards and automation may still report Semi-Annual Enterprise Channel while the app backstage shows Monthly Enterprise Channel. Any compliance check or report that keys on the channel name needs to expect both. If you build a detection or compliance rule on `UpdateChannel`, this is the thing that will surprise you.
- Semi-Annual Enterprise Channel support duration changed. Learn records eight months for a given version beginning July 2025, previously fourteen, and states that from July 2026 feature releases are supported for one month with a two month rollback, an effective three month window.

Two dates and one version number appear above. All three are read from Learn
rather than inferred: July 2026, Version 2606, and Semi-Annual Enterprise Channel
Version 2508 supported through 8 September 2026. No build numbers are invented
anywhere in this set.

Sources: Overview of update channels for Microsoft 365 Apps. Upcoming channel
unification: Semi-Annual Enterprise Channel to Monthly Enterprise Channel.
Configuration options for the Office Deployment Tool.

### Detection is registry based, not file version based

Every detection script here reads the Click-to-Run configuration registry rather
than checking a file version. File version detection breaks the moment the channel
delivers an update: the binaries change, the rule stops matching, and Intune
decides a healthy install is missing. Product presence does not change when the
build number changes, which is the property you actually want out of a detection
rule for a continuously serviced product.

## What could not be verified

Stated plainly, because a package that hides its soft spots is worse than one that
names them.

**`ProductReleaseIds` is not documented on Microsoft Learn.** The registry key
`HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` **is** documented, and
Learn names `UpdateChannel`, `CDNBaseUrl`, `UpdateUrl` and `UnmanagedUpdateURL`
under it. The value `ProductReleaseIds`, which the base, Visio and Project
detection scripts read, is not documented anywhere this fact-check could find. It
is the value the Click-to-Run client writes to record installed product IDs and it
is stable in practice, but it is observed behaviour rather than a contract. Read
it on a reference device carrying the build you intend to ship before trusting it
at scale. Each affected script says so in its header.

**No registry value listing installed language packs is documented on Learn
either.** The `M365-Lang-da-dk` detection script checks two locations, string
values under the Click-to-Run configuration key and `InstalledUIs` under
`HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\LanguageResources`. Neither is
documented for this purpose. This is the least certain element of the set and the
package README says so at length. Install `da-dk` by hand on a reference device,
read both locations, and adjust the script to whatever your build actually
populates.

**Combining `Add` and `Remove` in one configuration file.** Both elements are
documented, and Learn shows `Add` combined with `RemoveMSI`, but this fact-check
found no Learn example combining `Add` with `Remove` in a single file. The base
install XMLs do combine them. If validation shows the ODT honouring only one, split
the removal into a separate configuration file run before the install.

**Publisher retirement.** Publisher is a valid `ExcludeApp` ID and this set makes
no claim about its retirement, because the announcement lives on a
support.microsoft.com article rather than on Microsoft Learn and could not be
verified through the documentation tooling used here. No retirement date is
asserted anywhere in these packages. If Publisher matters to your estate, check
the current Microsoft Support article yourself.

**No ODT version is pinned.** The READMEs tell you to download the current Office
Deployment Tool from the Microsoft Download Center and do not name a build number,
because naming one this fact-check did not read would be a fabricated claim. Two
minimum versions that Learn does state are recorded where relevant: ODT
16.0.11615.33602 or later for `Version="MatchInstalled"` to work, and version
16.0.19929.20062 or later for the `TenantAssociationKey` property, which this set
does not use.

## Microsoft Learn URLs used

Every claim in this document and in the package files traces to one of these.

**Office Deployment Tool and configuration**

- https://learn.microsoft.com/microsoft-365-apps/deploy/office-deployment-tool-configuration-options
- https://learn.microsoft.com/microsoft-365-apps/deploy/overview-office-deployment-tool
- https://learn.microsoft.com/en-us/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run
- https://learn.microsoft.com/microsoft-365-apps/best-practices/build-dynamic-lean-universal-packages
- https://learn.microsoft.com/microsoft-365-apps/deploy/upgrade-from-msi-version

**Languages**

- https://learn.microsoft.com/microsoft-365-apps/deploy/overview-deploying-languages-microsoft-365-apps

**Update channels**

- https://learn.microsoft.com/microsoft-365-apps/updates/overview-update-channels
- https://learn.microsoft.com/en-us/microsoft-365-apps/updates/unified-update-channels
- https://learn.microsoft.com/microsoft-365-apps/updates/change-update-channels

**Teams and OneDrive**

- https://learn.microsoft.com/microsoft-365-apps/deploy/teams-install
- https://learn.microsoft.com/sharepoint/exclude-or-uninstall-previous-sync-client

**Intune**

- https://learn.microsoft.com/intune/app-management/deployment/add-win32
- https://learn.microsoft.com/intune/app-management/deployment/add-microsoft-365-windows
- https://learn.microsoft.com/intune/device-enrollment/windows/setup-status-page
- https://learn.microsoft.com/intune/app-management/deployment/troubleshoot-win32
- https://learn.microsoft.com/intune/device-configuration/settings-catalog/update-office

**Licensing reference, for the Project Plan 3 and Plan 5 service plan check**

- https://learn.microsoft.com/entra/identity/users/licensing-service-plan-reference
