# Define the application ID (Change this value for a different app)
$packageId = "Google.Chrome"
$action = "install"

Function Get-WingetCmd {
    $WingetCmd = $null

    # Try to find Winget executable in admin context
    try {
        $WingetPaths = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe" -ErrorAction Stop
        if ($WingetPaths) {
            $WingetCmd = $WingetPaths | Sort-Object -Property Name -Descending | Select-Object -First 1 -ExpandProperty FullName
        }
    } catch {
        Write-Host "Admin context Winget not found, checking user context..."
    }

    # Try to find Winget executable in user context if admin context is missing
    if (-not $WingetCmd -and (Test-Path "$env:LocalAppData\Microsoft\WindowsApps\winget.exe")) {
        $WingetCmd = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
    }

    # If still not found, exit with an error
    if (-not $WingetCmd) {
        Write-Host "Error: Winget not found on this device."
        Exit 1
    }

    Write-Host "Winget location: $WingetCmd"
    return $WingetCmd
}

# Execute the Winget install command
$WingetCmd = Get-WingetCmd
if (-not $WingetCmd) { 
    Exit 1 
}

$procOutput = & $WingetCmd $action "--id" $packageId "--source" "winget" "--silent" "--accept-package-agreements" "--accept-source-agreements" "--disable-interactivity" "--scope" "machine"

# Handle errors in execution
if ($procOutput -match "error" -or $procOutput -match "failed") {
    Write-Host "Installation failed. Winget output: $procOutput"
    Exit 1
}

# Verify installation success
if ($procOutput -match "successfully installed" -or $procOutput -match "already installed") {
    Write-Host "Package $packageId installed successfully."
    Exit 0
} else {
    Write-Host "Installation did not complete as expected."
    Exit 1
}
