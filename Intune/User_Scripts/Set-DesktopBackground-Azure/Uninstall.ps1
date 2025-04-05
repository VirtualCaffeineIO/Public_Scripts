# Uninstall.ps1
# Cleanup script for Intune to remove deployed wallpaper and folder

$path = "C:\ProgramData\CompanyBackgrounds\company-bg.jpg"
if (Test-Path $path) {
    Remove-Item $path -Force
    $parent = Split-Path $path
    if ((Get-ChildItem $parent).Count -eq 0) {
        Remove-Item $parent -Force
    }
    Write-Host "Wallpaper and folder cleaned up."
} else {
    Write-Host "No wallpaper file found to remove."
}
