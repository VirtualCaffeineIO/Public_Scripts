# platform-scripts

Scripts that reach a device through Devices, Scripts rather than as a package.
No `.intunewin`, no detection rule, no uninstall. Intune runs each one once per
device and records success or failure, and that is the whole model.

That constraint is what decides whether something belongs here. A script with
no payload files, no need to be re-evaluated, and nothing to uninstall fits.
Anything that needs an icon, a binary or a detection rule belongs in
[`win32-apps/`](../win32-apps) instead.

## What is here

| Folder | What it does |
|---|---|
| [`auto-timezone/`](./auto-timezone) | Documentation only, no packaged script yet. Field notes on forcing automatic time zone on while leaving the rest of location services off and under user control. |
| [`desktop-wallpaper/`](./desktop-wallpaper) | Sets the user's desktop wallpaper from a public URL, such as an Azure blob. |
| [`public-desktop-shortcut/`](./public-desktop-shortcut) | Creates a shortcut on the public desktop, pinned to a chosen browser with a custom icon, plus a removal script. |
| [`remove-personal-teams/`](./remove-personal-teams) | Removes the consumer Microsoft Teams app that ships in the Windows 11 image. |

`auto-timezone` is the exception to the category. It holds a Settings Catalog
recipe and a set of registry commands, not a deployable script.

## How this category is deployed

Devices, Scripts, Add, Windows 10 and later. Upload the `.ps1` and set:

| Setting | Usual value here |
|---|---|
| Run this script using the logged-on credentials | No, unless the script writes to the signed-in user's own profile |
| Enforce script signature check | No |
| Run script in 64 bit PowerShell Host | Yes |

Assign to a device group.

## What to expect from the platform

A script runs once per device and is not re-run when it fails, unless you
change the assignment or the script content. It is not a state enforcement
mechanism. If you need something corrected every time it drifts, that is a
remediation, and it belongs in [`remediations/`](../remediations).

Scripts here are PowerShell 5.1 compatible and log to
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`, or to
`C:\ProgramData` where the Intune log directory is not appropriate.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
