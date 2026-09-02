# haadj-rename

Renames a Hybrid Azure AD joined device to a serial-number-derived name during
Autopilot, using domain credentials supplied to the device as an encrypted
file. Packaged as a Win32 app and targeted at the Enrollment Status Page so the
rename happens before the device reaches the desktop.

A domain rename needs an account with rights on the computer object, and a
device mid-provisioning has no interactive user to supply one. That is the
whole reason this package exists in the shape it does.

## Files

| File | What it does |
|---|---|
| `install.ps1` | Renames to `HYB-<serial>`. |
| `install-DTLT.ps1` | Alternative payload. Renames to `DT-<serial>` or `LT-<serial>` depending on whether the device reports a battery. |
| `detection.ps1` | Intended as the Intune detection script. See the known issue below before you use it. |
| `RebootTask/` | Companion package that reboots the device after the ESP finishes, so the rename takes effect. See its own README. |

Pick one payload. `install.ps1` and `install-DTLT.ps1` are two answers to the
same question and are not meant to run together.

## Naming convention

Both payloads read the BIOS serial number from `Win32_BIOS` and use the first
nine characters when the serial is longer than nine.

| Payload | Battery present | Resulting name |
|---|---|---|
| `install.ps1` | not checked | `HYB-<first 9 of serial>` or `HYB-<serial>` |
| `install-DTLT.ps1` | no | `DT-<first 9 of serial>` or `DT-<serial>` |
| `install-DTLT.ps1` | yes | `LT-<first 9 of serial>` or `LT-<serial>` |

`install-DTLT.ps1` branches on `-gt 9` and `-lt 9` and has no branch for a
serial of exactly nine characters. A device with a nine-character serial is not
renamed at all and the script exits without error. Devices from a vendor with
fixed nine-character serials will silently keep their Autopilot default names.

## Credentials

Both payloads expect two files beside the script in the packaged content:

| File | Contents |
|---|---|
| `aeskey.txt` | The AES key used to encrypt the password. |
| `credpassword.txt` | The password, encrypted with that key by `ConvertFrom-SecureString -Key`. |

Neither file is committed here, and neither should be. Generate them on a
workstation you control, package them into the `.intunewin`, and keep the pair
out of source control.

The domain account is hard-coded as `ganlab\renamer`. Change it. That account
needs only the right to rename a computer object in the target OU, and it
should have nothing else.

Understand what this design gives away. The AES key and the ciphertext travel
together inside the package, which means anyone who can extract the
`.intunewin` can recover the password. The mitigation is the account, not the
encryption: scope it to one OU, give it no interactive logon rights, and rotate
it when the package is retired.

Both payloads write a transcript to `C:\temp\rename.txt`.

## Known issue in `detection.ps1`

`detection.ps1` has both of its `exit` statements commented out. As committed,
every path through the script writes to STDOUT and then falls off the end with
an implicit exit code of 0, so Intune reads the app as installed on every
device regardless of whether the rename succeeded. The failure branch, which
prints "There was an issue renaming the PC", reports success just as loudly as
the success branch.

It also uses `Write-Host` rather than `Write-Output`.

Do not deploy this as a detection rule as it stands. Either restore the `Exit 0`
and `Exit 1` lines and switch to `Write-Output`, or detect on the result the
rename actually produces.

## Deployment

Package the chosen payload plus `aeskey.txt` and `credpassword.txt` with
`IntuneWinAppUtil.exe`, add it as a Windows app (Win32) in system context, and
include it in the Enrollment Status Page blocking app list. Pair it with the
`RebootTask` package so the new name is applied before the user signs in.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
