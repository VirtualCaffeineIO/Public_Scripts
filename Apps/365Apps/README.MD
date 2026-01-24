# Visio & Project Add-ons for Microsoft Intune (Company Portal)

This repository contains ready-to-package **Microsoft Visio** and **Microsoft Project** Click-to-Run add-on installers for **Microsoft Intune**.
They are intended to be published as **Available** apps in **Company Portal**, so they install only when a licensed user requests them.

## What’s included

- Visio (Visio Plan 2) add-on package
- Project (Project Plan 3/5) add-on package
- Install / uninstall XML files for the Office Deployment Tool (ODT)
- CMD wrappers to orchestrate install/uninstall
- Detection scripts (C2R SKU-based; update-safe)
- Optional MSI cleanup scripts (removes MSI Visio/Project only; does **not** touch base Microsoft 365 Apps)

## Prerequisites

- Devices already have **Microsoft 365 Apps** installed (Click-to-Run).
- Users are assigned the appropriate Visio/Project licenses.
- Company Portal is installed and functional.

## Office Deployment Tool (ODT)

Download the evergreen Office Deployment Tool from Microsoft:
https://www.microsoft.com/download/details.aspx?id=49117

Extract it and copy `setup.exe` into the appropriate package folder(s) in this repo (Visio / Project) **before** packaging with IntuneWinAppUtil.

## Packaging (Win32)

Use **IntuneWinAppUtil.exe** (Intune Win32 App Packaging Tool).

Example:
- Source folder: `packages/Visio-Pro/`
- Setup file: `install-visio.cmd`
- Output folder: wherever you keep your `.intunewin` artifacts

Repeat for Project using `packages/Project-Pro/`.

## Intune configuration (recommended)

### Visio (Available)
- Install command: `install-visio.cmd`
- Uninstall command: `uninstall-visio.cmd`
- Detection rule: PowerShell script → `detection/Detect-VisioProRetail.ps1`
- Install behavior: System
- Assignment: Available to a Visio-licensed **user** group

### Project (Available)
- Install command: `install-project.cmd`
- Uninstall command: `uninstall-project.cmd`
- Detection rule: PowerShell script → `detection/Detect-ProjectProRetail.ps1`
- Install behavior: System
- Assignment: Available to a Project-licensed **user** group

## Notes

- XML uses `MatchInstalled` so Visio/Project inherit the existing Office language.
- Detection checks **only** for the Click-to-Run SKU (`VisioProRetail` / `ProjectProRetail`).
  MSI installs do **not** count as compliant and are removed during install.

## Author

Virtual Caffeine IO  
https://virtualcaffeine.io
