# win32-apps

Packages that reach a device as a Windows app (Win32). Each folder holds the
install, uninstall and detection content for one application or one piece of
configuration, ready to be wrapped with the Win32 Content Prep Tool.

## What is here

| Folder | What it deploys |
|---|---|
| [`m365-apps/`](./m365-apps) | Microsoft 365 Apps, as five Office Deployment Tool packages: enterprise base, business base, Visio, Project and a Danish language pack. |
| [`teams-new/`](./teams-new) | The new Microsoft Teams client, from its offline installer, plus public desktop and user profile shortcut scripts. |
| [`win11-upgrade-assistant/`](./win11-upgrade-assistant) | User-interactive Windows 11 upgrade. Downloads an ISO from Azure Blob Storage with AzCopy, mounts it, and launches setup through ServiceUI so it appears on the user's desktop. |
| [`win11-ui-defaults/`](./win11-ui-defaults) | Windows 11 Start menu, taskbar and Explorer defaults, applied to the current user and to the default profile. |
| [`desktop-background/`](./desktop-background) | Downloads a wallpaper from Azure Blob Storage and sets it for the signed-in user. |
| [`vcredist/`](./vcredist) | Visual C++ 2015 to 2022 redistributables, x64 and x86 together. |
| [`dotnet-3-5/`](./dotnet-3-5) | Enables the .NET Framework 3.5 optional feature, so it can be attached as a dependency. |
| [`autopilot-only-runner/`](./autopilot-only-runner) | A wrapper that runs an arbitrary payload only while Autopilot provisioning is still active, and never afterwards. |

## How this category is deployed

Wrap the folder, then add it in Intune under Apps, Windows, Add, Windows app
(Win32).

```
IntuneWinAppUtil.exe -c <source folder> -s <install file> -o <output folder>
```

`IntuneWinAppUtil.exe` is in [`_assets/`](../_assets), and upstream is
https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases

Install behavior is System for everything in this tree except the parts that
have to touch a user's own profile, which the individual READMEs call out.

## The detection contract

Intune counts a Win32 app as installed only when the detection script exits 0,
writes something to STDOUT, and writes nothing to STDERR. All three. An exit 0
with no output is the documented signal for not installed, which means the app
is re-offered on roughly a 24 hour cycle indefinitely. On a package that
downloads a Windows ISO or reinstalls Office, that is expensive.

Detection scripts use `Write-Output`, not `Write-Host`, and failure paths stay
silent rather than calling `Write-Error`. See [CONTRIBUTING.md](../CONTRIBUTING.md).

Two folders here have detection scripts that get this wrong as committed, and
each says so in its own README: `win11-upgrade-assistant/Scripts` and
`win11-ui-defaults`.

## Third-party binaries

No folder in this tree commits the vendor binaries it needs. The Windows 11
ISO, AzCopy, ServiceUI, the Teams installer, the Visual C++ redistributables
and the Office Deployment Tool are all named with a download source in the
folder README and fetched by whoever builds the package.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
