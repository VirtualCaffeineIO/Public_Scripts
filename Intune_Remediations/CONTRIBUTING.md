# Contributing to Intune Remediations

Thanks for considering contributing!

## How to Contribute

- Fork the repository and create your branch from `main`
- Follow the existing folder structure: each app should have its own folder
- Include a `README.md` in each app folder explaining what the remediation does
- Scripts should be well-commented, use PowerShell 5.1-compatible syntax, and include logging to the Intune log directory

## Coding Style

- Prefer `Write-Host` for script output (visible in logs)
- Avoid external dependencies — stick to built-in PowerShell and Winget

## Questions?

Open an issue or contact the repo author: [https://virtualcaffeine.io](https://virtualcaffeine.io)
