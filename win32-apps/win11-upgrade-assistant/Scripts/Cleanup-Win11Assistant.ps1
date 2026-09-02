<#
.SYNOPSIS
    Cleanup script for Win11 upgrade assistant. Deletes ISO and log files.
    Scheduled to run X days after upgrade completes.
.AUTHOR
    Virtual Caffeine IO
#>

$logRoot = "C:\ProgramData\Win11Assistant"
$logFile = "$logRoot\Win11UpgradeAssistant.log"
$isoFile = "$logRoot\Win11.iso"
$markerFile = "$logRoot\IME-Just-Ran.txt"

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -FilePath "$logRoot\Win11Cleanup.log" -Append -Encoding UTF8
}

Write-Log "Running Win11 Cleanup Task..."

try {
    if (Test-Path $isoFile) {
        Remove-Item $isoFile -Force
        Write-Log "Removed ISO file."
    }
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
        Write-Log "Removed log file."
    }
    if (Test-Path $markerFile) {
        Remove-Item $markerFile -Force
        Write-Log "Removed detection marker."
    }
} catch {
    Write-Log "ERROR during cleanup: $_"
}
