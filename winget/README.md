# winget

Five generic Winget helper scripts. None of them targets a specific
application. Each one carries a single `$packageId` variable at the top, and
changing that variable is how you make it deploy something else.

They are building blocks. The per-application folders in
[`../remediations`](../remediations) are what you get when these are filled in
and paired up.

## The scripts

| File | Role | Exit codes |
|---|---|---|
| `Install-App.ps1` | Installs `$packageId` from the winget source, machine scope, silently. | 0 installed or already installed, 1 otherwise |
| `Uninstall-App.ps1` | Uninstalls `$packageId` silently. | 0 uninstalled, 1 otherwise |
| `Detect-App.ps1` | Win32 app detection. Reports the installed version. | 0 installed, 1 not found |
| `Detect-Outdated-App.ps1` | Remediation detection. Compares the installed version against the version in the winget source. | 0 up to date, 1 outdated or not installed |
| `Remediate-Outdated-App.ps1` | Remediation. Upgrades `$packageId`. | 0 upgraded, 1 otherwise |

All five ship with `$packageId = "Google.Chrome"` as the worked example.

## Finding winget in system context

`Install-App.ps1` and `Remediate-Outdated-App.ps1` define a `Get-WingetCmd`
function that resolves the executable before calling it. It looks first under
`$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe`,
sorting descending by name so the newest package version wins, and falls back
to `$env:LocalAppData\Microsoft\WindowsApps\winget.exe`.

That lookup exists because `winget.exe` is not on the PATH for SYSTEM. A script
that simply calls `winget` works when a technician tests it in their own
session and fails when Intune runs it. If you write another script against
these, copy that function rather than assuming the shortcut.

`Detect-App.ps1` and `Detect-Outdated-App.ps1` call `winget.exe` directly
without the lookup, and parse its table output by splitting on whitespace and
taking the second field from the end. That parsing is positional and it depends
on the shape of the winget console table, which is not a stable contract.
Confirm both scripts against the winget build in your estate before you rely on
them.

## Known issue in Uninstall-App.ps1

`Uninstall-App.ps1` calls `Get-WingetCmd` but never defines it. The function
lives only in `Install-App.ps1` and `Remediate-Outdated-App.ps1`, and PowerShell
does not share functions between separately invoked scripts. As committed the
script fails on its first line of real work with a command-not-found error, so
the uninstall never runs.

Copy the `Get-WingetCmd` function from `Install-App.ps1` into it before use.
This README does not change the script.

## Using them as a Win32 app

Intune does not run a bare PowerShell script as a Win32 app, so the scripts have
to be wrapped. Download the Win32 Content Prep Tool from
https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases (a copy
is also in [`../_assets`](../_assets)), then:

```
IntuneWinAppUtil.exe -c C:\Path\To\Scripts -s Install-App.ps1 -o C:\Path\To\Output
```

Put `Install-App.ps1` and `Uninstall-App.ps1` in the same source folder so both
travel in the package. The detection script is uploaded to Intune directly and
does not need to be inside the `.intunewin`, though including it does no harm.

| Setting | Value |
|---|---|
| Install command | `powershell.exe -ExecutionPolicy Bypass -File .\Install-App.ps1` |
| Uninstall command | `powershell.exe -ExecutionPolicy Bypass -File .\Uninstall-App.ps1` |
| Install behavior | System |
| Detection rule | Script, `Detect-App.ps1` |

## Using them as a remediation

Pair `Detect-Outdated-App.ps1` with `Remediate-Outdated-App.ps1` under Devices,
Remediations, and schedule it weekly. That is the mechanism the application
folders in [`../remediations`](../remediations) are converting an estate towards:
one recurring update job per application, instead of a repackaging exercise per
release.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
