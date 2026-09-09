# not-intune

Work that is kept here because it is useful and because it came from the same
practice, but which has nothing to do with Intune and is not deployed to a
device by any means.

The folder exists so the rest of the repository can be trusted. Every other
tree here answers the question "how does this reach a device". This one does
not, and mixing it in with content that does would make that map a lie.

## What is here

| Folder | What it is |
|---|---|
| [`mfa-sweep/`](./mfa-sweep) | A pointer to MFASweep, Beau Bullock's tenant MFA assessment tool. The tool itself is not vendored here. |
| [`pki/`](./pki) | Scripts for standing up a certificate authority and its IIS-hosted CRL and AIA endpoints: `Root_CA-Config.ps1` and `PKI-IIS_Config.ps1`. |

## Read before running either

`mfa-sweep` is an assessment tool aimed at a tenant's authentication surface.
Run it only against a tenant you are authorised to test. Its README explains
why the copy that used to live here was removed rather than kept up to date.

`pki` builds a certificate authority. That is infrastructure with a long life
and consequences that outlast the person who ran the script, and the two files
carry no README of their own beyond a title. Read both scripts in full before
running either, and do not run them against an existing PKI.

## What does not belong here

Anything that reaches a Windows endpoint through Intune, in any form. If it is
a script, a package, a remediation or a Graph tool that configures the tenant,
it belongs in one of the other trees. This folder is for the things that would
otherwise be lost, labelled honestly.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
