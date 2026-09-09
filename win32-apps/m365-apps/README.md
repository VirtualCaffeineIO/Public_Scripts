# m365-apps

Microsoft 365 Apps deployment, as five separate Win32 packages built on the
Office Deployment Tool. One base install per licence type, three add-ons that
inherit whatever the base established.

Every folder here carries its own README with the worked example, the product
ID, and the reasoning behind each attribute in the XML. `MIGRATION.md` records
what was wrong with the packages this set replaced and cites the Microsoft
Learn page behind each correction. Read that file before changing anything in
this tree.

## The packages

| Folder | Product | Product ID | Assignment |
|---|---|---|---|
| `M365-Base` | Microsoft 365 Apps for enterprise | `O365ProPlusRetail` | Required, device group |
| `M365-Base-Business` | Microsoft 365 Apps for business | `O365BusinessRetail` | Required, device group |
| `M365-Visio` | Visio desktop app, Visio Plan 2 | `VisioProRetail` | Available for enrolled devices, user group |
| `M365-Project` | Project desktop app, Plan 3 or Plan 5 | `ProjectProRetail` | Available for enrolled devices, user group |
| `M365-Lang-da-dk` | Danish language pack | `LanguagePack` | Available for enrolled devices, user group |

Each folder holds an install XML, an uninstall XML, a detection script and a
README. There is no `setup.exe` in any of them: the Office Deployment Tool is
downloaded separately and packaged alongside the XML.

## The design in one paragraph

Exactly one package pins the estate's Office identity. `M365-Base` sets
`Channel` and `OfficeClientEdition` because it is the first install on the
device and there is nothing for the ODT to match against. Every other package
in this set deliberately omits both, because the ODT matches an existing
installation when those attributes are absent. That is what stops a Visio
request from re-channelling a device's entire Office install days later, which
is the failure the previous package set produced and `MIGRATION.md` documents.

## Two base packages, not one

`M365-Base` and `M365-Base-Business` differ by product ID and nothing else that
matters. A business licence and an enterprise product ID installs, then fails
to activate, and the detection script never matches what licensing recorded on
the device, so Intune reinstalls Office daily forever.

Assign the two to mutually exclusive device groups. Getting that scoping wrong
is the most expensive mistake available in this tree.

## Detection

All five detection scripts read `ProductReleaseIds` under
`HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration` rather than checking
a file version, because a channel update moves the binaries and breaks a file
version rule on a perfectly good install. They write one line to STDOUT and
exit 0 on the success path, and exit 1 silently on every failure path, which is
the contract Intune actually enforces.

`ProductReleaseIds` is not documented on Microsoft Learn. The scripts say so in
their own headers. Confirm the value on a reference device before you trust
this at scale.

Only `M365-Base` also checks architecture. The add-ons deliberately do not,
because they inherit the base install's architecture and a detection script
that demanded x64 would report a correctly installed 32-bit add-on as missing.

## Before you deploy

The worked estate throughout is Monthly Enterprise Channel, 64-bit, en-us, with
da-dk as the requestable extra. Substitute your own values. Every folder README
names the exact file and the exact attribute to change, and in every case the
install XML and the detection script must be changed together: they name the
same product ID or the package reinstalls forever.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
