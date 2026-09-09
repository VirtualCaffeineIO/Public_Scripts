<#
.SYNOPSIS
    Detection script for Windows 11 UI Defaults - Proactive Remediation

.DESCRIPTION
    Checks whether expected UI-related registry keys exist in HKCU for the logged-in user.

.AUTHOR
    Virtual Caffeine IO
.WWW
    https://virtualcaffeine.io
#>

$advanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$search   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$desktopIcons = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
$cloudContent = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
$classicMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

try {
    $valid = $true
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advanced -Name TaskbarAl -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advanced -Name HideFileExt -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advanced -Name ShowTaskViewButton -ErrorAction SilentlyContinue) -eq 0)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $advanced -Name StartShownOnUpgrade -ErrorAction SilentlyContinue) -eq 1)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $search -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue) -eq 1)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $desktopIcons -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -ErrorAction SilentlyContinue) -eq 1)
    $valid = $valid -and ((Get-ItemPropertyValue -Path $cloudContent -Name DisableSpotlightCollectionOnDesktop -ErrorAction SilentlyContinue) -eq 1)

    if (Test-Path $classicMenu) {
        $value = (Get-ItemProperty -Path $classicMenu -Name "(default)" -ErrorAction SilentlyContinue)."(" + "default" + ")"
        $valid = $valid -and ($value -eq "")
    } else {
        $valid = $false
    }

    if ($valid) {
        Write-Output "Compliant"
        exit 0
    } else {
        Write-Output "Not Compliant"
        exit 1
    }
} catch {
    Write-Output "Error: $_"
    exit 1
}
