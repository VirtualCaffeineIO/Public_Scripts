# Install.ps1
# This wrapper launches Set-Background.ps1 as the current logged-in user

$scriptPath = Join-Path $PSScriptRoot "Set-Background.ps1"
$blobUrl = "<REPLACE_WITH_YOUR_SAS_URL>"
$savePath = "C:\ProgramData\CompanyBackgrounds\company-bg.jpg"

Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" -blobUrl `"$blobUrl`" -savePath `"$savePath`"" -WindowStyle Hidden -Wait
