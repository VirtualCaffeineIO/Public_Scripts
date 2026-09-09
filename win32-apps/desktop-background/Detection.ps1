# Detection.ps1
# Returns success if the wallpaper exists on the system

$path = "C:\ProgramData\CompanyBackgrounds\company-bg.jpg"
if (Test-Path $path) {
    Write-Host "Wallpaper file found."
    exit 0
} else {
    Write-Host "Wallpaper file not found."
    exit 1
}
