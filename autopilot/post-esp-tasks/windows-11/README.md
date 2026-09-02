# post-esp-tasks/windows-11

A scheduled task that waits for the Windows 11 AppID policy converter to finish
and then reboots the device, once, at the end of Autopilot provisioning.

Structurally this is the same package as `haadj-rename/RebootTask`, with one
difference in the payload. On Windows 11, `appidpolicyconverter.exe` runs after
provisioning to compile application control policy. Rebooting while it is
working leaves that work incomplete. This version waits for the process rather
than sleeping for a fixed interval.

## Files

| File | What it does |
|---|---|
| `install.ps1` | Creates `C:\temp`, copies `PostESP-Script.ps1` into it, and registers `PostESP-Script.xml` as a scheduled task named `PostESP-Script`. |
| `PostESP-Script.ps1` | The task payload. Waits for `appidpolicyconverter`, then disables its own task and reboots. |
| `PostESP-Script.xml` | The scheduled task definition. |
| `Detection.ps1` | Intune detection script. |

## How the trigger works

The task subscribes to Security event ID 4647, the user initiated logoff event,
rather than running on a schedule. During Autopilot the provisioning session
logging off is what raises it. It runs as `S-1-5-18` at highest available run
level with a 72 hour execution time limit, and its action is
`powershell.exe -executionpolicy bypass c:\temp\PostESP-Script.ps1`.

Because any logoff raises 4647, the payload disables the task the first time it
fires. Without that the device would reboot at every logoff.

The task XML carries `<Author>SMBtotheCloud</Author>` from its origin. Cosmetic,
but it is not this repository's name.

## Payload behaviour

`PostESP-Script.ps1` creates `C:\temp`, writes the marker file
`C:\windows\system32\Tasks\ESP-TaskComplete`, starts a transcript at
`C:\temp\post-esp-task.txt`, then sleeps five seconds and enters a polling loop
at 150 millisecond intervals waiting for a process named
`appidpolicyconverter` to appear. When it appears the script calls
`Wait-Process` on it and blocks until it exits. It then disables the
`PostESP-Script` task, sleeps five seconds and calls `Restart-Computer -Force`.

The loop has no timeout. If `appidpolicyconverter` never starts, the script
polls indefinitely and the device is never rebooted by this package. The task's
72 hour execution time limit is the only ceiling. That is the trade this design
makes: it will not reboot early, and in exchange it can fail to reboot at all.

Unlike the `haadj-rename/RebootTask` variant, this payload does not carry a
commented-out `Unregister-ScheduledTask` line. The task is disabled, not
removed, and remains visible in Task Scheduler.

## Detection

`Detection.ps1` returns installed when either
`C:\windows\system32\tasks\PostESP-Script` or
`C:\windows\system32\tasks\ESP-TaskComplete` exists, covering both the
registered and the already-fired states. It writes to STDOUT and exits 0 on the
detected path, which is what Intune requires. It uses `Write-Host` rather than
`Write-Output`, against the convention in CONTRIBUTING.md.

## Deployment

Package `install.ps1`, `PostESP-Script.ps1` and `PostESP-Script.xml` with
`IntuneWinAppUtil.exe`. Install command:

```
powershell.exe -executionpolicy bypass -file .\install.ps1
```

Install behavior system. Detection rule: script, `Detection.ps1`. Add it to the
ESP blocking app list.

Deploy this or the `haadj-rename/RebootTask` package, not both. They register a
scheduled task under the same name, `PostESP-Script`, and write the same marker
file, so the second install overwrites the first and the detection scripts
cannot tell them apart.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
