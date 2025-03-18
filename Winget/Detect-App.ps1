# Define the application ID (Change this value for a different app)
$packageId = "Google.Chrome"

# Get latest available version
$WGSearch = winget.exe search -e --id $packageId --accept-source-agreements
$WGSearchOutput = $WGSearch -split "`r?`n"

if ($WGSearchOutput.Count -lt 2) {
    Write-Output "Failed to retrieve online version"
    exit 1
}

$WGOnlineVersion = ($WGSearchOutput[-1] -split "\s+")[-2]

# Get the currently installed version
$WGLocalSearch = winget.exe list -e --id $packageId
$WGLocalOutput = $WGLocalSearch -split "`r?`n"

if ($WGLocalOutput.Count -lt 2) {
    Write-Output "$packageId not found, detection failed"
    exit 1
}

$WGLocalVersion = ($WGLocalOutput[-1] -split "\s+")[-2]

if ([string]::IsNullOrEmpty($WGLocalVersion)) {
    Write-Output "Failed to detect installed version"
    exit 1
}

try {
    $OnlineVer = [System.Version]::Parse($WGOnlineVersion)
    $LocalVer = [System.Version]::Parse($WGLocalVersion)
} catch {
    Write-Output "Version parsing error"
    exit 1
}

if ($LocalVer -ge $OnlineVer) {
    Write-Output "$packageId is up to date."
    exit 0
} else {
    Write-Output "Outdated version detected for $packageId."
    exit 1
}
