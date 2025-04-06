<#
.SYNOPSIS
    Windows 11 Upgrade deployment script for Intune.
.DESCRIPTION
    Downloads Windows 11 ISO using AzCopy, mounts it, and launches setup.exe via ServiceUI from SYSTEM.
.AUTHOR
    Virtual Caffeine IO
    https://virtualcaffeine.io
#>

$logPath = "C:\ProgramData\Win11Assistant\Win11UpgradeAssistant.log"
$proofPath = "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt"
$isoPath = "C:\ProgramData\Win11Assistant\Win11.iso"
$azCopyPath = "$PSScriptRoot\Files\azcopy.exe"
$serviceUIPath = "$PSScriptRoot\Files\ServiceUI.exe"

# ===============================================
# Replace this with your full Azure Blob SAS URL:
$blobUrl = "<YOUR FULL BLOB SAS URL HERE>"
# ===============================================

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

New-Item -Path "C:\ProgramData\Win11Assistant" -ItemType Directory -Force | Out-Null
"[$(Get-Date)] Script started" | Out-File $proofPath -Encoding UTF8 -Force
Write-Log "=== Win11 Upgrade Script Started ==="

# Download ISO
try {
    Start-Process -FilePath $azCopyPath -ArgumentList "copy `"$blobUrl`" `"$isoPath`" --overwrite=true" -Wait -NoNewWindow
    Write-Log "ISO downloaded successfully."
} catch {
    Write-Log "AzCopy failed: $_"
    exit 1
}

# Mount ISO
try {
    $mount = Mount-DiskImage -ImagePath $isoPath -PassThru
    Start-Sleep -Seconds 5
    $driveLetter = ($mount | Get-Volume).DriveLetter + ":"
    $setupPath = "$driveLetter\setup.exe"
    Write-Log "Mounted ISO at $driveLetter"
} catch {
    Write-Log "Failed to mount ISO: $_"
    exit 1
}

# Launch setup.exe via ServiceUI
try {
    $arguments = "`"$setupPath`" /auto upgrade /eula accept /bitlocker AlwaysSuspend"
    Start-Process -FilePath $serviceUIPath -ArgumentList $arguments
    Write-Log "Setup.exe launched via ServiceUI"
} catch {
    Write-Log "Failed to launch setup: $_"
    exit 1
}
