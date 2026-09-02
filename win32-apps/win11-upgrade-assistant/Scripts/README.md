# win11-upgrade-assistant/Scripts

The Intune-side rules and the post-upgrade cleanup for the Windows 11 upgrade
package. None of these is the installer. `Launch-Win11-Setup.ps1`, one level
up, is the install command; these are the scripts you paste into the app's
Requirements and Detection tabs, plus the task that tidies up afterwards.

## Files

| File | Role |
|---|---|
| `Requirement-TPM2.ps1` | Requirement rule. Passes on TPM 2.x. |
| `DetectionRule.ps1` | Detection rule. Tests for the marker file the upgrade script drops. |
| `Detection-Win11-24H2.ps1` | Alternative detection rule. Tests for Windows 11 build 26100 or later. |
| `Cleanup-Win11Assistant.ps1` | Deletes the ISO, the log and the marker after the upgrade. |
| `Cleanup-Task-Template.xml` | Scheduled task definition that runs the cleanup script. |

## The two detection scripts answer different questions

`DetectionRule.ps1` tests for `C:\ProgramData\Win11Assistant\IME-Just-Ran.txt`.
That marker says the upgrade was launched, not that it succeeded. Use it if you
want Intune to stop re-offering the app to a device that has already been
handed the installer, which on a user-interactive upgrade is usually what you
want: the user may still be working through setup, and re-running the download
underneath them helps nobody.

`Detection-Win11-24H2.ps1` reads `Win32_OperatingSystem` and passes only when
the caption contains "Windows 11" and the build is 26100 or higher. That says
the upgrade finished. Use it if you want Intune to keep offering the app until
the outcome is real.

Pick one. They will disagree for the entire duration of an upgrade, and
`Cleanup-Win11Assistant.ps1` deletes the marker the first one depends on, which
flips that app back to not-installed some days after a successful upgrade.

## Known issue: both detection scripts exit 0 silently

Intune counts a Win32 app as installed only when the detection script exits 0
and writes something to STDOUT, with nothing on STDERR. An exit 0 with no
output is the documented signal for not installed.

`DetectionRule.ps1` and `Detection-Win11-24H2.ps1` both take their success path
by calling `exit 0` with no preceding output. As committed, neither can ever
report installed. A required app behind either rule is re-offered on roughly a
24 hour cycle indefinitely, which for this package means redownloading a
Windows ISO.

`Requirement-TPM2.ps1` has the same shape. The package README one level up says
to configure it with output type Integer, operator Equals, value 0, which reads
the script's STDOUT, and the script writes none.

Adding a `Write-Output` line before each `exit 0` is the fix. This README does
not change the scripts.

## Cleanup

`Cleanup-Win11Assistant.ps1` removes three files from
`C:\ProgramData\Win11Assistant`: `Win11.iso`, `Win11UpgradeAssistant.log` and
`IME-Just-Ran.txt`. It writes its own timestamped log to
`Win11Cleanup.log` in the same folder, and it wraps the deletions in
try/catch so a locked file does not fail the task.

Note that it deletes the detection marker. That is the interaction described
above.

`Cleanup-Task-Template.xml` is a template, not a ready task. Its
`<StartBoundary>` is the literal string `$(StartTime)`, which
`Launch-Win11-Setup.ps1` substitutes with a real timestamp before registering
the task. Registering this XML as it stands fails. The task runs as `S-1-5-18`
at highest available run level and calls:

```
powershell.exe -ExecutionPolicy Bypass -File "C:\ProgramData\Win11Assistant\Cleanup-Win11Assistant.ps1"
```

## Where these go in Intune

| Tab | Script |
|---|---|
| Requirements, additional requirement rule, script | `Requirement-TPM2.ps1`, output type Integer, Equals, 0 |
| Detection rules, use a custom detection script | `DetectionRule.ps1` or `Detection-Win11-24H2.ps1` |

The cleanup script and the task template are packaged into the `.intunewin`
alongside the installer. They are not uploaded to Intune separately.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
