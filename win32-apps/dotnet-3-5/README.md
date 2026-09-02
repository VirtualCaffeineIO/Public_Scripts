# dotnet-3-5

Enables the .NET Framework 3.5 Windows optional feature, packaged as a Win32
app so it can be made a dependency of the line-of-business application that
needs it.

.NET 3.5 is not installed on a modern Windows image. It is a Feature on Demand
that Windows fetches from Windows Update, or from a configured source, when it
is enabled. Making it a Win32 app rather than a configuration setting is what
lets you attach it as a dependency to the one application that requires it,
rather than enabling a legacy runtime everywhere.

## Files

| File | Role |
|---|---|
| `Install.ps1` | Imports the DISM module and enables the `NetFx3` feature online with `-NoRestart`. |
| `uninstall.ps1` | Imports the DISM module and disables `NetFx3` online with `-NoRestart`. |
| `detection.ps1` | Reports installed when the feature state is Enabled. |

Each is two or three lines. There is nothing hidden in them.

## Detection

`detection.ps1` reads the `NetFx3` feature state with
`Get-WindowsOptionalFeature -Online`, and on a match writes
".net 3.5 is enabled" with `Write-Output` and exits 0. Otherwise it writes
".net 3.5 is not enabled" and exits 1. That is the correct shape for an Intune
detection script: data on STDOUT and exit 0 on the installed path.

The state comparison is `-eq "enabled"` against a value PowerShell returns as
`Enabled`, which works because PowerShell string comparison is
case-insensitive by default.

## The source question

`Enable-WindowsOptionalFeature -Online -FeatureName NetFx3` with no `-Source`
retrieves the payload from Windows Update. On a device where Windows Update
access is restricted by policy, or where the "Specify settings for optional
component installation and component repair" Group Policy points at an
unreachable share, the enable fails and the install reports an error rather
than hanging.

If that applies to your estate, either add a `-Source` pointing at the
`sources\sxs` folder of a matching Windows image, or set the policy that allows
Features on Demand to come from Windows Update directly. Neither is done for
you here.

## Restart behaviour

Both scripts pass `-NoRestart`, so neither reboots the device. The feature is
usable after a restart. Set the Win32 app's device restart behavior to
"Determine behavior based on return codes" and let 3010 be handled as a soft
reboot, or accept that the feature becomes available at the user's next
restart.

## Deployment

Package the folder with `IntuneWinAppUtil.exe`:

```
IntuneWinAppUtil.exe -c . -s Install.ps1 -o .\Output
```

Add it as a Windows app (Win32).

| Setting | Value |
|---|---|
| Install command | `powershell.exe -ExecutionPolicy Bypass -File .\Install.ps1` |
| Uninstall command | `powershell.exe -ExecutionPolicy Bypass -File .\uninstall.ps1` |
| Install behavior | System |
| Detection rule | Script, `detection.ps1` |

Then attach it as a dependency of the application that needs it, rather than
assigning it directly.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
