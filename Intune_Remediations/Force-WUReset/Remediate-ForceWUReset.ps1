<#
.SYNOPSIS
Force a clean reset of Windows Update components and trigger WUfB patching.

.DESCRIPTION
This remediation script is intended for Intune-managed Windows 10 and Windows 11
devices. It performs a clean reset of Windows Update by:

1. Stopping key update services (wuauserv, bits, cryptsvc)
2. Deleting:
     - C:\Windows\SoftwareDistribution (entire folder)
     - All contents of C:\Windows\System32\catroot2
3. Restarting the services
4. Triggering a new Windows Update for Business scan, download, and install
   via UsoClient

The script does NOT reboot the device. Any required restart is handled by
your existing Windows Update for Business / Intune update ring settings.

Logging:
  C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ForceWUReset.log

.AUTHOR
Virtual Caffeine IO
https://virtualcaffeine.io
#>

[CmdletBinding()]
param()

$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ForceWUReset.log"

function Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logPath -Value "$timestamp $Message"
}

Log "----- Force Windows Update reset remediation starting -----"

function Stop-Svc {
    param([string]$Name)
    try {
        Log "Stopping service: $Name"
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
    }
    catch {
        Log "Could not stop $Name: $($_.Exception.Message)"
    }
}

function Start-Svc {
    param([string]$Name)
    try {
        Log "Starting service: $Name"
        Start-Service -Name $Name -ErrorAction SilentlyContinue
    }
    catch {
        Log "Could not start $Name: $($_.Exception.Message)"
    }
}

# 1. Stop core update services
Stop-Svc "wuauserv"
Stop-Svc "bits"
Stop-Svc "cryptsvc"

# 2. Delete SoftwareDistribution completely
$sd = "C:\Windows\SoftwareDistribution"
if (Test-Path $sd) {
    try {
        Log "Deleting SoftwareDistribution folder..."
        Remove-Item -Path $sd -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Log "Failed to delete SoftwareDistribution: $($_.Exception.Message)"
    }
}
else {
    Log "SoftwareDistribution folder not found (already removed)."
}

# 3. Delete catroot2 CONTENTS (not the folder itself)
$cr = "C:\Windows\System32\catroot2"
if (Test-Path $cr) {
    try {
        Log "Deleting catroot2 contents..."
        Get-ChildItem -Path $cr -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Log "Failed to delete catroot2 contents: $($_.Exception.Message)"
    }
}
else {
    Log "catroot2 folder not found."
}

# 4. Restart services
Start-Svc "cryptsvc"
Start-Svc "bits"
Start-Svc "wuauserv"

Log "Services restarted. Waiting 25 seconds before triggering scan."
Start-Sleep -Seconds 25

# 5. Trigger WUfB scan / download / install
try {
    Log "Triggering WUfB scan: UsoClient StartScan"
    UsoClient StartScan
    Start-Sleep -Seconds 30

    Log "Triggering download: UsoClient StartDownload"
    UsoClient StartDownload
    Start-Sleep -Seconds 30

    Log "Triggering install: UsoClient StartInstall"
    UsoClient StartInstall

    Log "UsoClient commands issued successfully. No reboot triggered by this script."
    Log "----- Force Windows Update reset remediation completed -----"
    exit 0
}
catch {
    Log "Error running UsoClient commands: $($_.Exception.Message)"
    exit 1
}
