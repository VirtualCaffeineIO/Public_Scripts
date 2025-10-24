####
# Original script from hahaman14 https://www.reddit.com/r/Intune/comments/1i6ncns/windows_update_remediation_v2/
#
# 
####
# --- Minimum required builds ---
$MinWin10Build = 19045  # Windows 10 22H2
$MinWin11Build = 26100  # Windows 11 24H2

# --- Get OS version ---
$OSversion = [Version](Get-ComputerInfo -Property OsVersion).OsVersion
Write-Output "Detected OS version: $OSversion"

# --- Initialize compliance flags ---
$OSCompliant = $false
$CUCompliant = $false
$Reasons = @()

# --- Check OS compliance ---
if ($OSversion.Build -lt 22000) {   # Windows 10
    if ($OSversion.Build -ge $MinWin10Build) {
        $OSCompliant = $true
    } else {
        $Reasons += "OS version below minimum required ($OSversion)"
    }
} else {  # Windows 11
    if ($OSversion.Build -ge $MinWin11Build) {
        $OSCompliant = $true
    } else {
        $Reasons += "OS version below minimum required ($OSversion)"
    }
}

# --- Determine last Monthly (B) CU ---
$daysCU = $null
$timeout = [DateTime]::Now.AddMinutes(5)

do {
    try {
        $lastupdate = Get-HotFix |
                      Where-Object {
                          $_.HotFixID -match '^KB5\d{6,}$' -and
                          $_.Description -match 'Security Update'
                      } |
                      Sort-Object -Property InstalledOn |
                      Select-Object -Last 1 -ExpandProperty InstalledOn

        if ($lastupdate) {
            $daysCU = (New-TimeSpan -Start $lastupdate -End (Get-Date)).Days
        }
    }
    catch {
        $Reasons += "Error querying update history"
    }

    if ([DateTime]::Now -gt $timeout) { break }
} until ($null -ne $daysCU)

# --- Check Monthly CU compliance ---
if ($daysCU -eq $null) {
    $Reasons += "Could not determine last Monthly Cumulative (B) Update"
} elseif ($daysCU -le 40) {
    $CUCompliant = $true
} else {
    $Reasons += "Last Monthly Cumulative (B) Update was $daysCU days ago"
}

# --- Final Compliance Result ---
if ($OSCompliant -and $CUCompliant) {
    Write-Output "System is compliant. Reason: All checks passed."
    exit 0
} else {
    $CombinedReason = $Reasons -join "; "
    Write-Output "System is non-compliant. Reason(s): $CombinedReason"
    exit 1
}
