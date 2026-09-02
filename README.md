# Public_Scripts

Scripts, packages and tools for Microsoft Intune and Windows device
management, published as the companion artifact to the Intune series at
[virtualcaffeine.io](https://virtualcaffeine.io).

Everything here is organised by **how it reaches a device**, because that is
what you already know when you come looking, and it stays true when the
articles get reorganised.

## The map

| Folder | What lives here | How it is deployed |
|---|---|---|
| [`win32-apps/`](./win32-apps) | Install, uninstall and detection sets | Packaged with IntuneWinAppUtil, added as a Windows app (Win32) |
| [`remediations/`](./remediations) | Detect and remediate pairs, one folder per target | Devices, Remediations |
| [`platform-scripts/`](./platform-scripts) | Run-once and user-context scripts that are not packages | Devices, Scripts |
| [`autopilot/`](./autopilot) | Enrollment, hardware hash, post-ESP tasks | Mixed, see each folder |
| [`graph-automation/`](./graph-automation) | Tools that run against Microsoft Graph | An admin workstation, not a device |
| [`detection-rules/`](./detection-rules) | Reusable requirement and detection snippets | Referenced by a Win32 app |
| [`winget/`](./winget) | Generic app-agnostic Winget helpers | Building blocks for the above |
| [`not-intune/`](./not-intune) | Kept for reference, honestly labelled | Not Intune work |
| [`_assets/`](./_assets) | Shared binaries the scripts reference | Not deployed |

## Two kinds of thing live here, and they are not interchangeable

Most of this repository is **device content**. It runs on an endpoint, in
system or user context, delivered by Intune. It is PowerShell 5.1 compatible
and it logs to the Intune log directory. That is what the guidelines below
describe.

[`graph-automation/`](./graph-automation) is **not that**. Those tools run on
an administrator's workstation, need PowerShell 7 and interactive delegated
Microsoft Graph consent, and write tenant configuration rather than touching a
device. Do not package one as a Win32 app and do not deploy one through
Intune. Each carries its own README saying what it needs and what it changes.

## Guidelines for the device content

- Safe to run through Intune.
- Most are system-context safe and work for non-admin users.
- Logging goes to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs` or
  to `C:\ProgramData` where that is not appropriate.
- Detection scripts write to STDOUT and exit 0. Intune reads a silent exit 0 as
  not installed, and anything on STDERR forces not-installed even when STDOUT
  and the exit code are correct. See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Third-party binaries are not vendored

Where a script needs a Microsoft or third-party executable, the folder README
names the download source rather than committing a copy. A vendored binary goes
stale silently, and redistribution is a question this repository does not need
to own.

## Licence

MIT. See [LICENSE](./LICENSE).

## Contributing

Open an issue or a PR. [CONTRIBUTING.md](./CONTRIBUTING.md) covers folder
structure, naming and the detection-script rule that is easy to get wrong.

## Author

Virtual Caffeine IO, [https://virtualcaffeine.io](https://virtualcaffeine.io)
