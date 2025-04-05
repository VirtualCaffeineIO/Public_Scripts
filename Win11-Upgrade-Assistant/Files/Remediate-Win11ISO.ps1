$log = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Win11Upgrade-Remediation.log"
$isoPath = "C:\ProgramData\Win11Assistant\Win11.iso"
$proofPath = "C:\ProgramData\Win11Assistant\IME-Just-Ran.txt"

function Write-Log {
    param ($msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $msg" | Out-File -FilePath $log -Append
}

Write-Log "=== Starting ISO cleanup ==="

$mounted = Get-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue
if ($mounted) {
    try {
        Dismount-DiskImage -ImagePath $isoPath
        Write-Log "Unmounted ISO image"
    } catch {
        Write-Log "Error unmounting ISO: $_"
    }
}

if (Test-Path $isoPath) {
    try {
        Remove-Item $isoPath -Force
        Write-Log "Deleted ISO file: $isoPath"
    } catch {
        Write-Log "Failed to delete ISO: $_"
    }
} else {
    Write-Log "No ISO found to delete."
}

if (Test-Path $proofPath) {
    try {
        Remove-Item $proofPath -Force
        Write-Log "Removed proof file: $proofPath"
    } catch {
        Write-Log "Failed to remove proof file: $_"
    }
} else {
    Write-Log "No proof file found to remove."
}

Write-Log "=== Remediation complete ==="
