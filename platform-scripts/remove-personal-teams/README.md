# remove-personal-teams

Removes the consumer Microsoft Teams app that ships in the Windows 11 image, so
that a managed device is left with only the Teams client the organisation
deploys.

## Files

| File | What it does |
|---|---|
| `remove_teams.ps1` | Removes Teams provisioned packages and installed Teams packages. |

## What it does

Two passes, in this order:

1. `Get-AppxProvisionedPackage -Online` filtered to a `DisplayName` like
   `*Teams*`, each result passed to `Remove-AppxProvisionedPackage`. This is
   the provisioned copy in the image, and removing it stops the app being
   installed for users created after this point.
2. `Get-AppxPackage -AllUsers` filtered to a `Name` like `*Teams*`, each result
   passed to `Remove-AppxPackage -AllUsers`. This removes it from profiles that
   already have it.

Both passes use `-ErrorAction SilentlyContinue`. Every step writes a line with
`Write-Output`, so the actions are visible in the IME log.

Run it in system context. `-AllUsers` and provisioned package removal both
require it.

## Read the wildcard before you deploy this

The filter is `*Teams*` in both passes. It is not limited to the consumer app.
Any Appx package whose display name or name contains "Teams" matches, which on
a Windows 11 device can include `MSTeams`, the new work Teams client that
Microsoft 365 Apps installs.

If you deploy the new Teams client through `win32-apps/teams-new`, or through
Microsoft 365 Apps, this script and that package will fight: one installs, the
other removes it on its next run. Narrow the filter to the consumer package
identity before you assign this alongside a Teams deployment.

## Attribution

The script header credits Jatin Makhija, cloudinfra.net, version 1.0.0. It is
not this repository's work and the header is left intact.

## Deployment

Devices, Scripts. Run this script using the logged-on credentials: No. Enforce
script signature check: No. Run script in 64 bit PowerShell: Yes.

## Author of this README

Virtual Caffeine IO, https://virtualcaffeine.io
