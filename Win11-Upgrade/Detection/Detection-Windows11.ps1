$os = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$build = [int]$os.CurrentBuild
$osUpgradeOk = ($build -ge 22631)

Try {
    $bitlockerStatus = (Get-BitLockerVolume -MountPoint "C:").ProtectionStatus
    $bitlockerOk = ($bitlockerStatus -eq 1)
} Catch {
    $bitlockerOk = $false
}

if ($osUpgradeOk -and $bitlockerOk) {
    Write-Host "Windows 11 24H2 or newer is installed AND BitLocker is re-enabled."
    exit 0
} else {
    exit 1
}