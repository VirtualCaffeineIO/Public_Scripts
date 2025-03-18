# Define the application ID (Change this value for a different app)
$packageId = "Google.Chrome"
$action = "uninstall"

# Execute the Winget uninstall command
$WingetCmd = Get-WingetCmd
if (-not $WingetCmd) { 
    Exit 1 
}

$procOutput = & $WingetCmd $action "--id" $packageId "--silent" "--accept-package-agreements" "--accept-source-agreements" "--disable-interactivity"

# Handle errors in execution
if ($procOutput -match "error" -or $procOutput -match "failed") {
    Write-Host "Uninstallation failed. Winget output: $procOutput"
    Exit 1
}

# Verify uninstallation success
if ($procOutput -match "successfully uninstalled") {
    Write-Host "Package $packageId uninstalled successfully."
    Exit 0
} else {
    Write-Host "Uninstallation did not complete as expected."
    Exit 1
}
