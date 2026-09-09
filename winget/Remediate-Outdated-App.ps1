# Define the application ID (Change this value for a different app)
$packageId = "Google.Chrome"

Function Get-WingetCmd {
    $WingetCmd = $null
    try {
        $WingetPaths = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe\winget.exe" -ErrorAction Stop
        if ($WingetPaths) {
            $WingetCmd = $WingetPaths | Sort-Object -Property Name -Descending | Select-Object -First 1 -ExpandProperty FullName
        }
    } catch {
        Write-Host "Admin context Winget not found, checking user context..."
    }
    if (-not $WingetCmd -and (Test-Path "$env:LocalAppData\Microsoft\WindowsApps\winget.exe")) {
        $WingetCmd = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
    }
    if (-not $WingetCmd) {
        Write-Host "Error: Winget not found on this device."
        Exit 1
    }
    return $WingetCmd
}

$WingetCmd = Get-WingetCmd
if (-not $WingetCmd) { Exit 1 }

$updateOutput = & $WingetCmd upgrade --id $packageId --silent --accept-package-agreements --accept-source-agreements

if ($updateOutput -match "installed") {
    Write-Host "$packageId updated successfully."
    Exit 0
} else {
    Write-Host "Update process failed. Winget output: $updateOutput"
    Exit 1
}
