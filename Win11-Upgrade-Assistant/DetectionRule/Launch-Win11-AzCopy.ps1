<#
.SYNOPSIS
    Windows 11 upgrade script with SAS URL input, upgrade UI, and scheduled cleanup.
.AUTHOR
    Virtual Caffeine IO
.WEBSITE
    https://virtualcaffeine.io
#>

# ====== SET THESE VARIABLES ======
# Replace these with your own Azure Blob SAS URL
$blobUrl = "<Your Blob URL>"  # Example: https://yourstorage.blob.core.windows.net/container/Win11.iso
$sasToken = "<Your SAS Token>" # Starts with ? and includes &sig=...
# =================================

if ($blobUrl -eq "<Your Blob URL>" -or $sasToken -eq "<Your SAS Token>") {
    Write-Host "ERROR: You must fill in your own blobUrl and sasToken values before running this script."
    exit 1
}

$sasUrl = "$blobUrl$sasToken"

# Log and file setup
$logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Win11Upgrade-Assistant.log"
$proofPath = "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt"
$isoPath = "C:\ProgramData\Win11Assistant\Win11.iso"
$azCopyPath = "$PSScriptRoot\Files\azcopy.exe"
$serviceUIPath = "$PSScriptRoot\Files\ServiceUI.exe"
$cleanupScriptPath = "$PSScriptRoot\Files\Remediate-Win11ISO.ps1"

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

New-Item -Path "C:\ProgramData\Win11Assistant" -ItemType Directory -Force | Out-Null
"[$(Get-Date)] Script execution started." | Out-File -FilePath $proofPath -Encoding UTF8 -Force
Write-Log "=== Launch-Win11-AzCopy.ps1 started ==="
Write-Log "Running as: $(whoami)"

if (!(Test-Path $azCopyPath)) {
    Write-Log "ERROR: azcopy.exe not found"
    exit 1
}
if (!(Test-Path $serviceUIPath)) {
    Write-Log "ERROR: ServiceUI.exe not found"
    exit 1
}
if (!(Test-Path $cleanupScriptPath)) {
    Write-Log "ERROR: Cleanup script missing"
    exit 1
}

Write-Log "Downloading ISO using AzCopy..."
Start-Process -FilePath $azCopyPath -ArgumentList "copy `"$sasUrl`" `"$isoPath`"" -Wait -NoNewWindow
Write-Log "ISO downloaded"

Write-Log "Mounting ISO..."
$mount = Mount-DiskImage -ImagePath $isoPath -PassThru
Start-Sleep -Seconds 5
$driveLetter = ($mount | Get-Volume).DriveLetter + ":"
$setupPath = "$driveLetter\setup.exe"

if (!(Test-Path $setupPath)) {
    Write-Log "ERROR: setup.exe not found"
    exit 1
}

Write-Log "Launching setup.exe with ServiceUI..."
Start-Process -FilePath $serviceUIPath -ArgumentList "`"$setupPath`""
Write-Log "setup.exe launched"

$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$cleanupScriptPath`""
$taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddDays(7)
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Settings $taskSettings
Register-ScheduledTask -TaskName "Win11Cleanup7Days" -InputObject $task | Out-Null
Write-Log "Scheduled cleanup task for 7 days later"

Write-Log "Script completed"
exit 0