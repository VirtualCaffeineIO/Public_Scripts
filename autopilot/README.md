# autopilot

Everything that happens before a device is a normally managed endpoint:
registering it into Windows Autopilot, and running work during the Enrollment
Status Page that cannot wait until afterwards.

This category is deployed three different ways, which is why each folder says
how rather than the category saying it once.

## What is here

| Folder | What it does | How it is deployed |
|---|---|---|
| [`enrollment/`](./enrollment) | Creates the Entra app registration with the Graph permissions Autopilot registration needs, and registers a device online with `Get-WindowsAutoPilotInfo`. | Run interactively by a technician. Not deployed by Intune. |
| [`hardware-hash/`](./hardware-hash) | Collects a device's hardware hash and uploads it to Azure Blob Storage, and merges collected hashes into one CSV for import. | Run on the device and on a technician workstation. Not deployed by Intune. |
| [`post-esp-tasks/`](./post-esp-tasks) | Work that must complete during provisioning: a domain rename for Hybrid Azure AD joined devices, and the controlled reboot that makes it stick. | Win32 apps in the ESP blocking app list. |

## The two registration paths

`enrollment/` is the online path. The device talks to Graph itself and appears
in the tenant's Autopilot device list without a file changing hands. It needs
an app registration with four `DeviceManagement*.ReadWrite.All` application
permissions and a client secret, and that secret ends up in plain text in the
script that uses it. It is a short-lived credential for a registration batch,
not a standing one.

`hardware-hash/` is the offline path, for devices that cannot reach Graph or
where you would rather not hand out a secret. The device writes a CSV and
uploads it to a blob container, someone merges the collected CSVs, and the
merged file is imported by hand.

Use the online path where you can. It is one step rather than three, and there
is no merged CSV to get out of date.

## post-esp-tasks

These are Win32 apps, but they are not ordinary ones. They are added to the
Enrollment Status Page blocking app list so provisioning waits for them, and
their whole purpose is to finish before the user reaches the desktop.

`post-esp-tasks/` contains two reboot packages, `haadj-rename/RebootTask` and
`windows-11`. Both register a scheduled task under the same name,
`PostESP-Script`, triggered by Security event 4647, and both write the same
marker file. Deploy one, not both.

## A caution that applies to this whole tree

Several scripts here set `Set-ExecutionPolicy Unrestricted -Force` and do not
restore the previous value, and one packages an AES key next to the ciphertext
it decrypts. Both are called out in the folder READMEs. Neither is an accident,
and neither is free. Read the folder README before you run anything in this
tree against a device you care about.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
