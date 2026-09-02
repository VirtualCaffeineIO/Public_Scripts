# wsus-detection.ps1 - Detection Script for WSUS Configuration

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
    Write-Host "WSUS configuration detected. Exiting with error code 1."
    exit 1
} else {
    Write-Host "No WSUS configuration found. Exiting with code 0."
    exit 0
}
