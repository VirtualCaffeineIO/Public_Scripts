# windows-update-force-check

Detects devices that have fallen behind on Windows quality updates or are below
a minimum OS build, and rebuilds the Windows Update client stack on the ones
that have.

This is the heaviest remediation in this repository. Read all of it before you
assign it.

## Files

| File | Role |
|---|---|
| `Detection-WindowsUpdates.ps1` | Detection script. |
| `Remediation-WindowsUpdates.ps1` | Remediation script. |

Both carry a header crediting the original to hahaman14, posted to r/Intune:
https://www.reddit.com/r/Intune/comments/1i6ncns/windows_update_remediation_v2/

## Detection

Two independent checks, and the device must pass both.

| Check | Threshold in the committed script | Where to change it |
|---|---|---|
| Minimum Windows 10 build | 19045, which is 22H2 | `$MinWin10Build` |
| Minimum Windows 11 build | 26100, which is 24H2 | `$MinWin11Build` |
| Age of the last monthly cumulative update | 40 days | the `$daysCU -le 40` comparison |

It reads the OS version from `Get-ComputerInfo`, treats build 22000 and above
as Windows 11, and picks the threshold accordingly. It then looks through
`Get-HotFix` for the most recently installed entry whose `HotFixID` matches
`^KB5\d{6,}$` and whose `Description` is `Security Update`, and measures how
many days ago that was.

The hotfix query sits in a retry loop with a five minute ceiling, because
`Get-HotFix` is unreliable on a device that is busy at the moment the
remediation schedule fires. A device where the query never succeeds is reported
non-compliant with the reason "Could not determine last Monthly Cumulative (B)
Update", which is honest but also means a busy device gets the full remediation
below.

Both build numbers are absolute values, not relative ones. They go stale. Review
them whenever the servicing baseline moves.

## Remediation

It runs, in order:

1. `Repair-WindowsImage -RestoreHealth` online, logging to
   `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\#DISM.log`.
2. Deletes `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` entirely.
3. Clears pause values under
   `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings`:
   `PausedQualityDate`, `PausedFeatureDate`, `PausedQualityStatus`,
   `PausedFeatureStatus`.
4. Clears pause and deferral values under
   `HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update`, including
   `DeferFeatureUpdatesPeriodInDays`, and the `_ProviderSet` and
   `_WinningProvider` companions of the pause start times.
5. Sets `AllowDeviceNameInTelemetry` and `AllowTelemetry_PolicyManager` to 1
   under `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`.
6. Sets `GStatus` to 2 under the `Appraiser\GWX` key.
7. Stops BITS, wuauserv and cryptsvc, deletes the BITS queue manager data
   files, deletes `SoftwareDistribution` and `catroot2`, resets the two service
   security descriptors with `sc.exe sdset`, re-registers 36 DLLs with
   `regsvr32`, resets Winsock, and restarts the three services.
8. Runs `USOClient.exe StartInteractiveScan`, then sleeps for five minutes.
9. Downloads SetupDiag from `https://go.microsoft.com/fwlink/?linkid=870142`
   and writes its output to the Intune log directory.
10. Registers a scheduled task named `MidnightShutdown`, running as SYSTEM at
    23:59, that checks device uptime and, if the device has not rebooted in the
    last day, calls `shutdown.exe /r /f /t 300` with a user-facing message.

## Three things that will bite you

**It reboots users.** Step 10 is the reason the script's own header says to use
it with caution on kiosks. Any device that stays non-compliant keeps getting the
midnight restart task re-registered. The five minute warning is the only notice
the user gets, and the message text names a ticketing system that is not yours.

**Step 2 deletes a policy key wholesale.** If anything in your estate writes
Windows Update policy to
`HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`, this removes it,
not just the pause values. On a cleanly Intune-managed device that key should
be empty anyway, which is the assumption the script is built on. Confirm that
assumption before you assign it.

**Two hard-coded values are not yours.** `$dir = "C:\BH IT\"` is the SetupDiag
download folder, left over from the environment this came from, and the script
never creates it, so on a device without that folder the download throws and
the diagnostic step is skipped. The shutdown message names "OneSupport". Change
both.

Step 8's five minute sleep, plus the detection script's five minute retry
ceiling, means a single evaluation can occupy the IME for a long time. Schedule
it daily at most.

## Deployment

Devices, Remediations. Run this script using the logged-on credentials: No.
Enforce script signature check: No. Run script in 64 bit PowerShell: Yes.

Pilot it. This rewrites service security descriptors, deletes the update cache
and registers a reboot task, and it does all three on any device the detection
calls non-compliant, including one that was merely too busy to answer
`Get-HotFix`.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
