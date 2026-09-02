# _assets

Shared files that other folders in this repository refer to. Nothing here is
deployed on its own and nothing here is packaged as a Win32 app.

## What is in here

| File | What it is |
|---|---|
| `IntuneWinAppUtil.exe` | Microsoft Win32 Content Prep Tool. Wraps a source folder into the `.intunewin` file that a Windows app (Win32) requires. Almost every `win32-apps/` README invokes it by name. |
| `SetACL.exe` | SetACL, by Helge Klein. Takes ownership of and rewrites the DACL on a protected path. Called by `remediations/disable-whfb/WHfB-Disable-Remediation.ps1` to get write access to the `Ngc` folder before deleting it. |
| `Store_Apps.txt` | Plain notes, not a script. Lists Microsoft Store product IDs for the inbox apps the author assigns an uninstall for, so a Store app uninstall assignment can be built without looking each ID up again. |
| `start2.bin` | An opaque binary. The file name matches the Windows 11 Start menu pinned layout file that lives under the `Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy` package in a user profile. No script in this repository references it and its provenance is not recorded, so treat it as an unlabelled artifact until someone can say which build and which layout it came from. |

## The vendoring question

The root README states that third-party binaries are not vendored and that
folder READMEs name a download source instead. The two executables in this
folder are the exception, and they are an exception in fact rather than by
argument. Both are copies. Both go stale silently. If you are packaging
anything from this repository, prefer the upstream download:

- Win32 Content Prep Tool: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases
- SetACL: https://helgeklein.com/setacl/

Neither vendor's licence question is settled by this repository. If you
redistribute either binary you own that decision.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
