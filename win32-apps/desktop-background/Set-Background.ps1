<#
.SYNOPSIS
Downloads and sets a desktop background for the current user on Windows 11.

.DESCRIPTION
This script downloads a wallpaper from an Azure Storage Blob (via SAS URL),
saves it locally, sets it as the desktop wallpaper, and forces a refresh.

.AUTHOR
Virtual Caffeine IO
.WEBSITE
https://virtualcaffeine.io
#>

param (
    [string]$blobUrl = "<REPLACE_WITH_YOUR_SAS_URL>",
    [string]$savePath = "C:\ProgramData\CompanyBackgrounds\company-bg.jpg"
)

$folder = Split-Path $savePath
if (-not (Test-Path $folder)) {
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri $blobUrl -OutFile $savePath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Failed to download wallpaper: $_"
    exit 1
}

$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name Wallpaper -Value $savePath

$signature = @"
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
"@
$SPI_SETDESKWALLPAPER = 0x0014
$UPDATE_INI_FILE = 0x01
$SEND_CHANGE = 0x02
Add-Type -MemberDefinition $signature -Name WinAPI -Namespace SystemWallpaper -PassThru | Out-Null
[SystemWallpaper.WinAPI]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $savePath, $UPDATE_INI_FILE -bor $SEND_CHANGE)

Write-Host "Desktop wallpaper updated successfully."
