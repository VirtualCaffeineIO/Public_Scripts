# Improved detection script: verifies Windows 11 24H2 or later
$osInfo = Get-CimInstance Win32_OperatingSystem
$build = [int]$osInfo.BuildNumber
$caption = $osInfo.Caption

if ($caption -like "*Windows 11*") {
    if ($build -ge 26100) {
        exit 0  # Meets 24H2 requirement
    }
}
exit 1
