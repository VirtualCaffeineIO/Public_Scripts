# Wrapper.ps1
$logFolder = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$logFile = Join-Path $logFolder "AutopilotOnlyApp.log"
Start-Transcript -Path $logFile -Append

$autopilotRegPath = "HKLM:\SOFTWARE\Microsoft\Provisioning\AutopilotSettings"
if (-not (Test-Path $autopilotRegPath)) {
    Write-Output "Not in Autopilot provisioning. Exiting script."
    Stop-Transcript
    exit 0
}

Write-Output "In Autopilot provisioning phase. Running main script..."

# Run your payload script (swap this out to reuse)
$payloadScript = Join-Path $PSScriptRoot "RemoveBloat.ps1"
if (Test-Path $payloadScript) {
    & $payloadScript
    if ($LASTEXITCODE -eq 0) {
        New-Item -Path "C:\ProgramData\AutopilotOnlyApp" -ItemType Directory -Force | Out-Null
        New-Item -Path "C:\ProgramData\AutopilotOnlyApp\script_completed.flag" -ItemType File -Force | Out-Null
    }
} else {
    Write-Warning "Payload script not found: $payloadScript"
}

Stop-Transcript
exit 0
