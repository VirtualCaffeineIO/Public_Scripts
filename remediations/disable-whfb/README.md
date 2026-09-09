# disable-whfb

Removes a configured Windows Hello for Business PIN from a device by deleting
the `Ngc` container that holds it.

This is the blunt instrument, and it is the one that works. Disabling Windows
Hello for Business by policy stops new enrolments. It does not remove a
credential a user already has, and a device that already holds a PIN keeps
offering it indefinitely. Deleting the container is what actually clears it.

## Files

| File | Role |
|---|---|
| `WHfB-Disable-Detection.ps1` | Detection script. |
| `WHfB-Disable-Remediation.ps1` | Remediation script. |

The path both operate on is
`C:\windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc`.

## Detection

Enumerates the `Ngc` folder with `-ErrorAction SilentlyContinue`. If it returns
anything, the script writes "WHfB PIN configured" and exits 1, which is
non-compliant and triggers the remediation. If it returns nothing, it writes
"WHfB PIN not configured" and exits 0.

## Remediation

1. Creates `C:\temp` if it does not exist.
2. Downloads `SetACL.exe` to `C:\Temp\SetACL.exe`.
3. Uses SetACL to take ownership of the `Ngc` tree for the local administrators
   group.
4. Uses SetACL again to grant administrators full control and reset the DACL on
   every child object.
5. Deletes the `Ngc` folder recursively.
6. Deletes `C:\temp\SetACL.exe`.

The two SetACL calls are the point of the script. `Ngc` is protected by the
system and SYSTEM cannot simply delete it. Ownership has to be taken first.

## Known issue: the download URL does not return the binary

The remediation downloads SetACL from a GitHub `/blob/` URL pinned to a commit
in this repository's own history. A `/blob/` URL returns the GitHub HTML page
that displays the file, not the file. `C:\Temp\SetACL.exe` therefore receives a
web page, the two SetACL calls fail, and the `Remove-Item` that follows fails
on the still-protected folder. The script reports no error of its own because
nothing checks the download.

A `raw.githubusercontent.com` URL, or a copy staged from a location you control,
returns the actual binary. This README does not change the script.

A copy of `SetACL.exe` is present in `_assets/` in this repository. Upstream is
Helge Klein: https://helgeklein.com/setacl/

## Read this before you deploy it

Deleting `Ngc` removes the device's Hello container. Every user who signed in
with a PIN on that device signs in with a password afterwards, once, and
re-enrols if policy still allows it. Pair this with the policy that stops
re-enrolment or the remediation will be undone by the next sign-in.

Neither script logs to the Intune log directory. Their output goes to the
remediation's own output column in the Intune console and nowhere else.

## Deployment

Devices, Remediations. Run this script using the logged-on credentials: No.
Enforce script signature check: No. Run script in 64 bit PowerShell: Yes.

Assign to a pilot group first. This deletes a credential store, and a mistake
in scoping is a mistake every user on those devices notices at the same moment.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
