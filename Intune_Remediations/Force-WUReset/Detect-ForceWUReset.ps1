<#
.SYNOPSIS
Detection script for a "force Windows Update reset" Intune remediation.

.DESCRIPTION
This script always returns a non-compliant exit code so that the remediation
script runs on every evaluation. Use this when you want to forcibly reset
Windows Update state and trigger a new WUfB patching cycle on targeted devices.

Exit code:
    1 = Non-compliant (always) -> remediation runs

.AUTHOR
Virtual Caffeine IO
https://virtualcaffeine.io
#>

[CmdletBinding()]
param()

Write-Output "Force mode: marking device as non-compliant so remediation will run."
exit 1
