# Define the application ID (Change this value for a different app)
$packageId = "Google.Chrome"

# Get the installed version
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

Write-Output "$packageId is installed, version: $WGLocalVersion"
exit 0
