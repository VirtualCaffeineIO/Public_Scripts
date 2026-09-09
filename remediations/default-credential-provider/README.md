# default-credential-provider

Forces the Windows sign-in screen back to the classic username and password
tile on devices where Web Sign-in or a Temporary Access Pass has been used.

## The problem this solves

Windows records the credential provider a user last signed in with and offers
it first next time. That memory outranks what the user sees, so a device where
someone signed in once with a TAP keeps presenting the Web Sign-in tile
afterwards, even where policy names the password provider as the default. The
help desk sees it as "the logon screen changed and will not change back".

The provider is identified by GUID. The password provider is
`{60b78e88-ead8-445c-9cfd-0b87f74ea6cd}`, and both scripts carry it in a single
variable at the top.

## Files

| File | Role |
|---|---|
| `Detect-DefaultCredentialProvider.ps1` | Detection script. |
| `Remediate-DefaultCredentialProvider.ps1` | Remediation script. |

Both operate on
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI`.

## Detection

Reports compliant, exit 0, only when `LastUsedCredentialProvider` exists and
matches the password provider GUID, compared case-insensitively. It reports
non-compliant, exit 1, when the registry path is missing, when the value is
absent or blank, when the value is some other provider, and when reading it
throws. Every path writes a line explaining which case it hit.

Failing closed on an error is deliberate. The remediation is idempotent, so a
false non-compliant costs one wasted write and nothing else.

## Remediation

Creates the `LogonUI` key if it is missing, then sets both
`LastUsedCredentialProvider` and `DefaultCredentialProvider` to the password
provider GUID. It exits 0 on success and 1 on failure, with a line of output
either way.

Setting `DefaultCredentialProvider` here overlaps with configuration policy,
and the script says so in its own comments. If you already set the default
provider through a configuration profile, this line keeps the two values
aligned rather than replacing that policy. If you do not, this becomes the only
thing setting it, which is a weaker arrangement than a policy because nothing
reports on drift between remediation runs.

## What this does not do

It does not disable Web Sign-in or TAP. Both remain available behind the "Sign-in
options" control. This changes which tile is offered first, nothing more. If the
intent is to stop those methods being used at all, that is an authentication
methods policy decision in Entra ID, not a registry value on the device.

## Deployment

Devices, Remediations. Upload the detection and remediation scripts as a pair.
Run this script using the logged-on credentials: No. Enforce script signature
check: No. Run script in 64 bit PowerShell: Yes.

Schedule it daily. The value it corrects is rewritten by Windows at every sign-in
that uses another provider, so this is a standing correction rather than a
one-off fix.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
