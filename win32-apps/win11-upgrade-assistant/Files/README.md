# Win11-Upgrade-Assistant support binaries

This folder holds the third-party binaries the upgrade scripts call. They are
not committed here. Download them yourself and place them beside this file
before packaging.

| File | Where it comes from |
|---|---|
| `azcopy.exe` | AzCopy, from Microsoft: https://learn.microsoft.com/azure/storage/common/storage-use-azcopy-v10 |
| `ServiceUI.exe` | Microsoft Deployment Toolkit, `Templates\Distribution\Tools\x64\ServiceUI.exe` after installing MDT |

Neither is redistributed in this repository. Both are Microsoft binaries under
their own terms, they change independently of these scripts, and a vendored
copy goes stale without anyone noticing.

An earlier revision of this folder contained `azcopy.zip`, which a sibling
readme described as holding both executables. The file was two bytes of text
and had never been a real archive, so any package built from it could not work
and the failure looked like a script bug. It has been removed.
