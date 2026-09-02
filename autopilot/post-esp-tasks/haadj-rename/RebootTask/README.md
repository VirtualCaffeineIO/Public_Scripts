# haadj-rename/RebootTask

Registers a scheduled task that reboots the device once the Enrollment Status
Page has finished and the provisioning user has logged off. It exists so that a
rename applied during the ESP takes effect without the user being asked to do
anything.

Packaged as a Win32 app in its own right, separate from the rename payload
beside it.

## Files

| File | What it does |
|---|---|
| `Install.ps1` | Creates `C:\temp`, copies `PostESP-Script.ps1` into it, and registers `PostESP-Script.xml` as a scheduled task named `PostESP-Script`. |
| `PostESP-Script.ps1` | The task payload. Drops a marker file, disables its own task, waits two seconds, and forces a restart. |
| `PostESP-Script.xml` | The scheduled task definition. |
| `detection.ps1` | Intune detection script. |

## How the trigger works

The task in `PostESP-Script.xml` is not time-based. It subscribes to Security
event ID 4647, which is the "user initiated logoff" event. During Autopilot,
the ESP's provisioning session logging off is what raises it, so the reboot
follows the end of provisioning rather than a guessed delay.

It runs as `S-1-5-18`, the SYSTEM account, at highest available run level,
with an execution time limit of 72 hours. The action is
`powershell.exe -executionpolicy bypass c:\temp\PostESP-Script.ps1`.

Two consequences worth knowing before you deploy this. Any user logoff raises
4647, not only the provisioning one, so the task must disable itself the first
time it fires or the device reboots on every subsequent logoff. It does, which
is the `disable-scheduledtask` line in the payload. And the task XML carries
`<Author>SMBtotheCloud</Author>` from its origin. It is cosmetic and it does not
affect behaviour, but it is not this repository's name.

## Payload behaviour

`PostESP-Script.ps1` creates `C:\temp`, writes the marker file
`C:\windows\system32\Tasks\ESP-TaskComplete`, starts a transcript at
`C:\temp\post-esp-task.txt`, disables the `PostESP-Script` task, sleeps two
seconds and calls `Restart-Computer -Force`.

The `Unregister-ScheduledTask` line is present but commented out. The task is
disabled rather than removed, so it stays visible in Task Scheduler after the
device is provisioned. That is a deliberate choice if you want the evidence and
an untidy one if you do not.

## Detection

`detection.ps1` returns installed when either the task file
`C:\windows\system32\tasks\PostESP-Script` or the marker file
`C:\windows\system32\tasks\ESP-TaskComplete` exists. That covers both states:
the task registered and not yet fired, and the task fired and disabled.

It writes to STDOUT and exits 0 on the detected path, which is what Intune
requires. It uses `Write-Host` rather than `Write-Output`, which the repository
convention in CONTRIBUTING.md advises against for detection scripts.

## Deployment

Package `Install.ps1`, `PostESP-Script.ps1` and `PostESP-Script.xml` with
`IntuneWinAppUtil.exe`. Install command:

```
powershell.exe -executionpolicy bypass -file .\Install.ps1
```

Install behavior system. Detection rule: script, `detection.ps1`. Add it to the
ESP blocking app list after the rename package.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
