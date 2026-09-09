# detection.ps1
$flagPath = "C:\ProgramData\AutopilotOnlyApp\script_completed.flag"
if (Test-Path $flagPath) {
    Write-Output "Script has already run during Autopilot"
    exit 0
} else {
    Write-Output "Script has NOT run yet"
    exit 1
}
