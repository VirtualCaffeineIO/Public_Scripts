# Contributing

Thanks for considering contributing.

## How to contribute

- Fork the repository and create your branch from `main`.
- Follow the existing folder structure. Every package, remediation or script set
  gets its own folder under the tree that matches how it is deployed.
- Include a `README.md` in every folder, named exactly that. It says what the
  thing does, how it is configured in Intune, and what it assumes about the
  estate.
- Scripts use PowerShell 5.1 compatible syntax, are commented, and log to the
  Intune log directory (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`)
  or to `C:\ProgramData` where that is not appropriate.

## Coding style

- Prefer `Write-Host` for progress output in install and remediation scripts.
  It is visible in the IME log and it does not pollute the pipeline.
- **Detection scripts are the exception, and getting this wrong is a real bug.**
  Intune evaluates a Win32 custom detection script as detected only when the
  script writes to STDOUT and exits 0. `Write-Host` does not write to STDOUT in
  the way the agent reads, so a detection script must use `Write-Output`. A
  script that exits 0 silently is read as not installed, and the app reinstalls
  on every sync. Anything written to STDERR also forces a not-installed result
  even when STDOUT is correct and the exit code is 0, so keep detection failure
  paths silent rather than calling `Write-Error`.
- Avoid external dependencies. Stick to built-in PowerShell, Winget, and
  Microsoft-supplied tooling.
- No em dashes or en dashes anywhere, in scripts, XML comments or markdown.

## Naming

Folders are lowercase and hyphenated. Files keep PowerShell's usual
`Verb-Noun.ps1` casing. Do not create two files whose names differ only by
case: Git is case-sensitive, Windows and macOS are not, and the pair cannot
both exist in a working tree.

## Questions

Open an issue, or contact the repo author: [https://virtualcaffeine.io](https://virtualcaffeine.io)
