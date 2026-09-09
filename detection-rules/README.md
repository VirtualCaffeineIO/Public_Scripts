# detection-rules

Small scripts that answer one question about a device, meant to be pasted into
a Win32 app's Requirements or Detection rules tab rather than deployed on their
own.

Nothing here is packaged and nothing here is assigned. A folder in this tree
exists because the same check is needed by more than one app, and keeping one
copy is better than keeping four that drift.

## What is here

| Folder | What it checks |
|---|---|
| [`tpm-version/`](./tpm-version) | Whether the device reports TPM 2.0 or 2.1, read from `Win32_Tpm` in the `root\CIMV2\Security\MicrosoftTpm` namespace. |

## How this category is used

In Intune, open the Win32 app, then either:

- **Requirements**, Add, Script. Set script output type, operator and value to
  match what the script returns. `tpm-version` is documented for Integer,
  Equals, 0.
- **Detection rules**, Rules format: Use a custom detection script.

The two tabs read the same script differently. A requirement rule gates whether
the app is offered at all. A detection rule decides whether it is already
installed. A script written for one is not automatically correct in the other.

## The output contract

Both tabs read the exit code and STDOUT. Intune treats a script as passing only
when it exits 0 and writes data to STDOUT, and anything on STDERR forces a
failure even alongside a clean exit code. A silent exit 0 is read as a failure,
not a pass.

Use `Write-Output`. `Write-Host` does not reach STDOUT in the way the agent
reads it, and a script that relies on it can pass in a console and fail in
Intune. `Detect-TPMVersion.ps1` currently uses `Write-Host` on both paths.

## Adding one

One folder per check, lowercase and hyphenated, holding the script and a
README that states what the script returns, which tab it is meant for, and the
exact output type, operator and value to configure.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
