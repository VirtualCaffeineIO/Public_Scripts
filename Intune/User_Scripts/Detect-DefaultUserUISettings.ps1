$hiveName = "HKLM\DefaultUserTemp"
$ntuserDat = "C:\Users\Default\NTUSER.DAT"

# Don't proceed if Default profile isn't there
if (!(Test-Path $ntuserDat)) {
    Write-Host "Default profile not found."
    exit 1
}

# Load the hive
$loadResult = & reg.exe load $hiveName $ntuserDat 2>&1
if ($loadResult -match "error" -or $LASTEXITCODE -ne 0) {
    Write-Host "Failed to load registry hive."
    exit 1
}

Start-Sleep -Milliseconds 500

try {
    $valid = $true

    $advKey = "Registry::HKLM\DefaultUserTemp\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $searchKey = "Registry::HKLM\DefaultUserTemp\Software\Microsoft\Windows\CurrentVersion\Search"
    $classicKey = "Registry::HKLM\DefaultUserTemp\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

    $valid = $valid -and ((Get-ItemPropertyValue -Path $advKey -Name "TaskbarAl" -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advKey -Name "HideFileExt" -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advKey -Name "ShowTaskViewButton" -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $searchKey -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue) -eq 1)

    if (Test-Path $classicKey) {
        $defaultValue = (Get-ItemProperty -Path $classicKey -Name "(default)" -ErrorAction SilentlyContinue)."(" + "default" + ")"
        $valid = $valid -and ($defaultValue -eq "")
    } else {
        $valid = $false
    }

} catch {
    Write-Host "Exception occurred during registry read."
    $valid = $false
}

# Unload the hive
Start-Sleep -Milliseconds 300
reg.exe unload $hiveName | Out-Null

if ($valid) {
    exit 0
} else {
    exit 1
}
