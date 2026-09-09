# remediations

Detect and remediate pairs, one folder per target, deployed through Devices,
Remediations in Intune.

Most of this tree exists for one purpose: eliminating legacy MSI and EXE
installations of third-party applications and standardising on Winget, so that
updates can be handled by a single weekly remediation rather than by a
repackaging exercise per application per version.

The rest of the tree is device state that has to be corrected repeatedly rather
than once. A configuration profile sets a value. A remediation notices when
something has changed it back.

## The goal

- Remove applications installed by MSI or EXE, whatever put them there.
- Reinstall the same application from Winget, so there is one source of truth.
- Keep it current with a scheduled Winget remediation, instead of a new package
  every release.

Office, Teams, OneDrive and SQL Server are explicitly excluded from Winget
enforcement. Those four have their own servicing channels, their own update
mechanisms and their own reasons to be left alone, and Winget is not the right
authority over any of them. Microsoft 365 Apps is deployed from
[`../win32-apps/m365-apps`](../win32-apps/m365-apps) instead.

## Folder shape

Each application folder holds three files:

```
<app-name>/
├── Detect-<AppName>.ps1
├── Remediate-<AppName>.ps1
└── README.md
```

**Detection.** Looks for the application under both the 32-bit and 64-bit
uninstall registry paths, and through Winget. It exits 1 when the application
is present by a legacy method, which is what triggers the remediation.

**Remediation.** Removes every version it found, using the uninstall string
recorded in the registry, then installs the current version from Winget.

Both log to
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\<AppName>Remediation.log`.

The application folders are a one-time conversion. Once an estate is converted,
run a generic Winget update remediation against it instead. The building blocks
for that are in [`../winget`](../winget).

## Available remediations

Application standardisation:

- [7-Zip](./7-zip)
- [Google Chrome](./chrome)
- [Mozilla Firefox](./firefox)
- [GitHub CLI](./github-cli)
- [GitHub Desktop](./github-desktop)
- [Greenshot](./greenshot)
- [Notepad++](./notepad-plus-plus)
- [PowerShell 7](./powershell-7)
- [PuTTY](./putty)
- [Webex](./webex)
- [Zoom](./zoom)

Device state:

- [default-credential-provider](./default-credential-provider), forces the
  logon screen back to the password provider after Web Sign-in or a TAP has
  been used.
- [disable-whfb](./disable-whfb), removes a configured Windows Hello for
  Business PIN by deleting the `Ngc` container.
- [win11-ui-defaults](./win11-ui-defaults), re-applies Windows 11 Start menu,
  Explorer and desktop preferences for the signed-in user.
- [windows-update-force-check](./windows-update-force-check), detects devices
  behind on quality updates or below a minimum build and rebuilds the update
  stack. The heaviest thing in this tree. Read its README first.
- [windows-update-reset](./windows-update-reset), unconditional Windows Update
  reset and forced WUfB scan.
- [wsus-cleanup](./wsus-cleanup), removes WSUS and Windows Update policy keys
  from migrated devices.

## Setting one up in Intune

1. Take the detection and remediation scripts from the folder you want.
2. In the Intune admin center, go to **Devices**, **Remediations**, and create
   a new script package.
3. Upload the `Detect-*.ps1` file as the detection script and the
   `Remediate-*.ps1` file as the remediation script.
4. Set **Run this script using the logged-on credentials** to No, **Enforce
   script signature check** to No, and **Run script in 64 bit PowerShell** to
   Yes, unless the folder README says otherwise.
5. Assign to a pilot group and set a schedule.
6. Read the results in the console, and the device-side logs under
   `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.

Pilot first, every time. A remediation runs on a schedule against every device
in scope, so a scoping mistake is a mistake that repeats.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for folder structure, naming and the
detection script conventions.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
