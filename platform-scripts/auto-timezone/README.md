# auto-timezone

**This folder is documentation. There is no packaged script here yet.** What
follows is a working recipe recorded from a live environment: a Settings
Catalog profile plus a short set of registry commands. Nothing in this folder
is deployable as it stands. Wrap the commands in a script with logging before
you use them.

## The problem

Automatic time zone on Windows depends on the location service. Turning
location on wholesale to get it is not acceptable in Europe or anywhere else
with a real position on location data, and turning location off wholesale
leaves travelling users with a clock that is wrong until someone fixes it by
hand.

The arrangement below forces automatic time zone on, administered centrally,
while leaving every other location consumer soft disabled and under user
control. Users who want Weather or News location can have it. Everyone else
gets nothing on by default.

Deploying this to existing users preserves their current location selections,
but only for apps named in the user-controlled list. Any app not in that list
is disabled with no user control, and every application installed later is too
unless it is added.

## Two findings worth stating first

Adding `MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy` to the policy is
what made automatic time zone work. It is in the user-controlled list below.

Intune device location worked without any policy addition. Nothing
Intune-related appears under Settings, Privacy and security, Location, Recent
activity.

## The Settings Catalog profile

Devices, Configuration, New Policy, Windows 10 and later, Settings Catalog.

### Privacy

| Setting | Value |
|---|---|
| Let Apps Access Location | Force Deny |
| Let Apps Access Location Force Allow These Apps | `windows.immersivecontrolpanel_cw5n1h2txyewy` |

**Let Apps Access Location User In Control Of These Apps.** These are the
standard ones. Use `Get-AppxPackage` to find anything else installed in your
own environment and add its package family name here.

```
Microsoft.WindowsCamera_8wekyb3d8bbwe
microsoft.windowscommunicationsapps_8wekyb3d8bbwe
Microsoft.WindowsMaps_8wekyb3d8bbwe
MSTeams_8wekyb3d8bbwe
MicrosoftTeams_8wekyb3d8bbwe
Microsoft.BingNews_8wekyb3d8bbwe
Microsoft.OutlookForWindows_8wekyb3d8bbwe
Microsoft.BingWeather_8wekyb3d8bbwe
Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy
MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy
Microsoft.Win32WebViewHost_cw5n1h2txyewy
```

### System

| Setting | Value |
|---|---|
| Allow Location | Force Location Off |

Force Location Off is described in the catalog as: all Location Privacy
settings are toggled off and grayed out, users cannot change the settings, and
no apps are allowed access to the Location service, including Cortana and
Search.

That description and the registry commands in the next section pull in opposite
directions, and this is the one part of the recipe that is not resolved here.
The commands write an Allow consent value and start the geolocation service on
the same device the profile is telling to force location off. The recipe was
recorded as working. Test the order of application and the end state on a
reference device before you trust it across an estate, rather than assuming one
half cancels the other.

## The device-side commands

Automatic time zone still has to be switched on. These are the raw commands.
Wrap them with logging before deploying, or accept that a failure is silent.

```powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate\" -Name "Start" -Type "DWORD" -Value "3" -Force

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "String" -Value "Allow" -Force

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type "DWord" -Value 1 -Force

Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue

W32tm /resync /force
```

What each one does:

| Command | Effect |
|---|---|
| `tzautoupdate` `Start` = 3 | Sets the Auto Time Zone Updater service to manual start, which is the state in which automatic time zone is on. |
| `ConsentStore\location` `Value` = `Allow` | Grants the machine-wide location consent the time zone updater reads. |
| `Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}` `SensorPermissionState` = 1 | Enables the location sensor override. |
| `Start-Service lfsvc` | Starts the Geolocation Service, so the change takes effect without a reboot. |
| `W32tm /resync /force` | Forces an immediate time resynchronisation rather than waiting for the next scheduled one. |

Forcing this on, administered by an administrator only, is a deliberate trade.
It produces a small number of support requests when it breaks, in exchange for
removing the constant stream of questions from travelling users whose clocks
are wrong.

## What this leaves you with

Every location service soft disabled except the Settings app, which is always
on. Users keep control of the apps in the user-controlled list. Automatic time
zone is on and cannot be turned off by the user.

## What is still missing

A packaged script with logging, a detection method, and a decision about
whether this ships as a platform script or as a remediation. Automatic time
zone is state that drifts, which argues for a remediation.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
