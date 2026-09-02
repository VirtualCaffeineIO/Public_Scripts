# public-desktop-shortcut

Creates a shortcut on the public desktop, so it appears for every user on the
device, and pins it to a chosen browser with a custom icon.

The worked example is an Office 365 portal shortcut that opens in Chrome.
Everything about it is meant to be edited.

## Files

| File | What it does |
|---|---|
| `Shortcut-PublicDesktop.ps1` | Creates `C:\mem`, copies an icon file into it, and writes `C:\users\public\desktop\Office365.lnk`. |
| `Uninstall-PublicShortcut.ps1` | Removes a shortcut from the public desktop. |

## What the create script sets

| Shortcut property | Value in the committed script |
|---|---|
| Shortcut path | `C:\users\public\desktop\Office365.lnk` |
| Target path | `C:\Program Files\Google\Chrome\Application\chrome.exe` |
| Arguments | `https://portal.office.com` |
| Icon location | `C:\mem\O365.ico` |
| Description | `O365 Shortcut` |

Setting the target to a browser and putting the URL in `Arguments` is what
forces the shortcut to open in that specific browser. If you want the user's
default browser instead, put the URL in `TargetPath` and delete the
`$Shortcut.Arguments` line. The script's own header comment says the same
thing.

Hard-coding Chrome means the shortcut is broken on any device where Chrome is
not installed at that path. Check that assumption against the estate before you
assign this, or use the default-browser form.

## The icon file

The script runs `Copy-Item ".\O365.ico" -Destination "c:\mem\O365.ico"`.
`O365.ico` is not committed in this folder. Supply your own and package it
alongside the script, or the copy fails and the shortcut is created with no
icon.

The script header names two ways to produce one: a `convertto-icon.ps1` helper,
which is also not in this repository, or an online converter such as
https://convertio.co/jpg-ico/ .

## Known issue: the uninstall does not match the install

The create script writes `Office365.lnk`. The uninstall script removes
`Office 365.lnk`, with a space. As committed, the uninstall never removes the
shortcut the install created, and it fails with a not-found error instead. Fix
one to match the other before you deploy the pair. This README does not change
either script.

## Deployment

This is content for Devices, Scripts rather than a Win32 app, unless you need
the icon file to travel with it, in which case package both with
`IntuneWinAppUtil.exe` and deploy it as a Windows app (Win32) in system
context. The public desktop is a machine-wide location, so run it in system
context either way.

## Author

Virtual Caffeine IO, https://virtualcaffeine.io
