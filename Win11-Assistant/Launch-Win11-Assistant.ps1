<#
.SYNOPSIS
    Downloads and runs the Windows 11 Installation Assistant from Microsoft.
.DESCRIPTION
    This script pulls the latest Windows 11 installer directly from Microsoft's CDN and initiates the upgrade quietly.
    While it minimizes user prompts, it still requires user interaction.
.AUTHOR
    Virtual Caffeine IO
.WEBSITE
    https://virtualcaffeine.io
#>

$installerUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"  # Always points to latest Installation Assistant
$installerPath = "$env:ProgramData\Win11UpgradeAssistant.exe"

Write-Host "Downloading Windows 11 Installation Assistant from Microsoft..."
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

if (Test-Path $installerPath) {
    Write-Host "Launching the Installation Assistant..."
    Start-Process -FilePath $installerPath -ArgumentList "/quietinstall" -Wait
    Write-Host "Upgrade launched."
} else {
    Write-Error "Failed to download the Installation Assistant."
    exit 1
}