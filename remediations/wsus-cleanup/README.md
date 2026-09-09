# wsus-cleanup

Removes WSUS and Windows Update policy registry keys from a device, so that a
co-managed or recently migrated device takes its updates from Windows Update
for Business rather than from a WSUS server it may no longer be able to reach.

The usual case is a device that came from an on-premises estate and still has
`UseWUServer` and a `WUServer` URL written into policy. Intune's update rings
apply, the device ignores them, and the update reports look like a client
failure rather than a configuration conflict.

## Files

| File | Role |
|---|---|
| `WSUS-Detection.ps1` | Detection script. |
| `WSUS-Remediation.ps1` | Remediation script. |

Both check the same two keys:

- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`

## Detection

Tests for the presence of either key. If either exists it writes which one it
found and exits 1, non-compliant. If neither exists it exits 0.

Presence of the key is the whole test. It does not read `UseWUServer`, it does
not read `WUServer`, and it does not distinguish a WSUS configuration from any
other policy that happens to live under the same path. Any value written there
by any means reads as WSUS.

## Remediation

Repeats the same check, and if either key exists it:

1. Stops `wuauserv` with `-Force`.
2. Deletes both keys recursively.
3. Deletes `C:\Windows\SoftwareDistribution` and
   `C:\Windows\System32\catroot2`.
4. Starts `wuauserv`.

Deleting `SoftwareDistribution` discards the local update cache and the update
history the device has accumulated. That is intentional, because a cache built
against a WSUS catalogue is not useful once the device points at Windows
Update, but it does mean the device redownloads everything it needs on its next
scan and that its visible update history in Settings starts over.

## Two cautions

**It deletes the policy key, not the WSUS values.** Anything else stored under
`HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate` goes with it. On a
device managed entirely by Intune that key should hold nothing you want to
keep. Confirm that before assigning.

**It overlaps with `windows-update-force-check`.** That remediation deletes the
same policy key and clears the same caches as part of a much larger routine.
Running both on the same devices means two scripts fighting over the same state
on the same schedule. Pick one.

Neither script writes to the Intune log directory. Output appears in the
remediation's output column in the Intune console.

## Deployment

Devices, Remediations. Run this script using the logged-on credentials: No.
Enforce script signature check: No. Run script in 64 bit PowerShell: Yes.

Assign it to the migrated devices, not to the whole estate. On a device that
never had WSUS the detection is a cheap no-op, but the blast radius if the key
is being used for something else is a policy key you cannot get back.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
