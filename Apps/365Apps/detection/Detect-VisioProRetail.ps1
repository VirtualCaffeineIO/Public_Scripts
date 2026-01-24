# Detect-VisioProRetail.ps1
# Exit 0 = Visio C2R detected (installed)
# Exit 1 = Not detected

$regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
if (-not (Test-Path $regPath)) { exit 1 }

$cfg = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
if ($cfg.ProductReleaseIds -match "VisioProRetail") { exit 0 }

exit 1
