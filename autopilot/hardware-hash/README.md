# autopilot/hardware-hash

Collecting Autopilot hardware hashes from devices that cannot reach Graph
directly, and merging the results into one CSV for import.

This is the offline path. Where a device can register itself, use
`autopilot/enrollment` instead: it is one step rather than three.

## Files

| File | What it does |
|---|---|
| `HardwareHashtoBlob.ps1` | Runs on the target device. Generates its hardware hash CSV and uploads it to an Azure Storage blob container with AzCopy. |
| `Merge-CSV.ps1` | Runs on a technician workstation. Concatenates a folder of per-device hash CSVs into a single `Merged-Hashes.csv`, keeping one header row. |

## HardwareHashtoBlob.ps1

Run it as SYSTEM or as a local administrator on the device to be registered.
It:

1. Creates `C:\hhash`.
2. Reads the BIOS serial number from `Win32_BIOS`.
3. Installs the NuGet package provider and the `Get-WindowsAutoPilotInfo`
   script from the PowerShell Gallery, and sets the execution policy to
   Unrestricted.
4. Writes the hash to `C:\hhash\<serial>-Hash.csv`.
5. Downloads AzCopy from `https://aka.ms/downloadazcopy-v10-windows`, expands
   it, and moves `azcopy.exe` into `C:\hhash`.
6. Copies the CSV to the blob container.
7. Deletes `C:\hhash` entirely, AzCopy included.

One value must be set before use. `$sasurl` is the string `"your blob URL"` as
committed. Replace it with a container SAS URL that carries write and add
permissions. A read-only SAS produces a silent no-op followed by the cleanup
step, so there is nothing left on disk to explain the failure.

The script sets `Set-ExecutionPolicy Unrestricted -Force` and does not restore
the previous value.

AzCopy is not committed here. It is downloaded at run time from the Microsoft
link above.

## Merge-CSV.ps1

Prompts for two paths: the folder holding the collected CSVs, and the folder to
write the merged file into. It keeps the header from the first file, skips it in
every file after that, and appends to `Merged-Hashes.csv` in the output folder.

It appends. Running it twice against the same output folder produces a file
with every device listed twice. Delete or move the previous `Merged-Hashes.csv`
before a second run.

The merged CSV is what you import under Devices, Enrollment, Devices in the
Windows Autopilot device list.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
