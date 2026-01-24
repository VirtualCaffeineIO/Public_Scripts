# Remove-MSI-Project.ps1
# Removes MSI-based Microsoft Project only (does not touch base Microsoft 365 Apps)

$apps = Get-ItemProperty `
  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
  -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match "^Microsoft Project" }

foreach ($app in $apps) {
  Start-Process "msiexec.exe" -ArgumentList "/x $($app.PSChildName) /qn /norestart" -Wait
}
