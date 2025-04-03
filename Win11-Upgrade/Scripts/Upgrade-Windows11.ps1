# Windows 11 Upgrade Script via Scheduled Task
# Author: Virtual Caffeine IO
# Website: https://virtualcaffeine.io

$TaskName = "Win11Upgrade"
$SetupExe = "$PSScriptRoot\..\Files\Windows11Upgrade\setup.exe"
$SetupArgs = "/auto upgrade /eula accept /noreboot"
$TriggerTime = (Get-Date).AddSeconds(15)
$WorkingDir = Split-Path $SetupExe

$tpm = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction SilentlyContinue
if (-not $tpm -or $tpm.SpecVersion -notmatch "^2\.[0-9]+") {
    Write-Host "TPM not compatible or not found. Exiting upgrade."
    exit 1
}

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$Action = New-ScheduledTaskAction -Execute $SetupExe -Argument $SetupArgs -WorkingDirectory $WorkingDir
$Trigger = New-ScheduledTaskTrigger -Once -At $TriggerTime
$Principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal
Register-ScheduledTask -TaskName $TaskName -InputObject $Task

Start-Sleep -Seconds 10
Start-ScheduledTask -TaskName $TaskName

while ((Get-ScheduledTask -TaskName $TaskName).State -eq "Running") {
    Start-Sleep -Seconds 10
}

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Start-Sleep -Seconds 5
$upgradeFolder = "$PSScriptRoot\..\Files"
if (Test-Path $upgradeFolder) {
    Remove-Item -Path $upgradeFolder -Recurse -Force -ErrorAction SilentlyContinue
}