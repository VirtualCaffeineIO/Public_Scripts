# Define the path where New Microsoft Teams is installed
$teamsPath = "C:\Program Files\WindowsApps"

# Define the filter pattern for Microsoft Teams installer
$teamsInstallerName = "MSTeams_*"

# Retrieve items in the specified path matching the filter pattern
$teamsNew = Get-ChildItem -Path $teamsPath -Filter $teamsInstallerName -ErrorAction SilentlyContinue

# Check if Microsoft Teams is listed in Appx packages
$teamsAppx = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*Teams*" }

# Evaluate both conditions to determine if Microsoft Teams is installed
if ($teamsNew -and $teamsAppx) {
    # Display message if Microsoft Teams is found
    Write-Host "Microsoft Teams client is installed."
    exit 0
} else {
    # Display message if Microsoft Teams is not found
    Write-Host "Microsoft Teams client not found."
    exit 1
}
