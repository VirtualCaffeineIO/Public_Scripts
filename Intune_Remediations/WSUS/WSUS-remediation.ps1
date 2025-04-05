# wsus-remediation.ps1 - Remediation Script to Remove WSUS Entries

Write-Host "Checking WSUS registry keys..."
$WSUSKeys = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
)

$WSUSConfigured = $false

foreach ($key in $WSUSKeys) {
    if (Test-Path $key) {
        $WSUSConfigured = $true
        Write-Host "WSUS registry key found: $key"
    }
}

if ($WSUSConfigured) {
    Write-Host "WSUS configuration detected. Proceeding with cleanup..."
    
    # Stop Windows Update Service
    Write-Host "Stopping Windows Update service..."
    Stop-Service wuauserv -Force
    
    # Remove WSUS registry keys
    foreach ($key in $WSUSKeys) {
        if (Test-Path $key) {
            Write-Host "Removing WSUS registry key: $key"
            Remove-Item -Path $key -Recurse -Force
        }
    }

    # Reset Windows Update Components
    Write-Host "Resetting Windows Update components..."
    Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

    # Restart Windows Update Service
    Write-Host "Starting Windows Update service..."
    Start-Service wuauserv
    
    Write-Host "WSUS entries removed and Windows Update reset successfully."
} else {
    Write-Host "No WSUS configuration found. No action required."
}
