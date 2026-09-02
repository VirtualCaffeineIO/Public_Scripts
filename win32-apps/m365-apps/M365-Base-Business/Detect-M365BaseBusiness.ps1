#Requires -Version 5.1
<#
    Detect-M365BaseBusiness.ps1
    Intune Win32 custom detection script for the M365-Base-Business package.
    Windows PowerShell 5.1 compatible.

    THE DETECTION CONTRACT

    Per Microsoft Learn, "Add, Assign, and Monitor a Win32 App in Microsoft
    Intune", Step 4, the Intune agent reads the exit code, STDOUT and STDERR.
    The app is INSTALLED only when the script exits 0 AND writes data to STDOUT
    AND writes nothing to STDERR. Exit 0 with empty STDOUT is NOT installed.
    Anything on STDERR is NOT installed regardless of the exit code.

    So the success path writes a line and exits 0, every failure path exits 1
    in silence, and the body is wrapped in try/catch so no error record can
    reach STDERR and invert an otherwise good result.

    WHY THIS SCRIPT IS SEPARATE FROM THE ENTERPRISE ONE

    It looks for O365BusinessRetail, not O365ProPlusRetail. A single detection
    script covering both product IDs would report a device as correctly
    installed while it holds the wrong product for its licence, which is the
    exact condition that needs to be visible in Intune rather than hidden.

    WHY REGISTRY AND NOT FILE VERSION

    File version detection breaks on the next channel update. Product presence
    does not change when the build number changes.

    VERIFICATION STATUS

    HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration is documented on
    Microsoft Learn. The value name ProductReleaseIds used below is NOT
    documented on Learn. Confirm it on a reference device that already carries
    the build you intend to ship before you trust this at scale.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Worked example estate. Substitute your own values.
#   Product  : Microsoft 365 Apps for business
#   Platform : 64-bit
# For Microsoft 365 Business Standard (no Teams) or Business Premium (no
# Teams), Learn maps the plan to O365BusinessEEANoTeamsRetail. Change this
# value and the install XML together. They must always name the same product.
# ---------------------------------------------------------------------------
$ExpectedProductId = 'O365BusinessRetail'
$ExpectedPlatform  = 'x64'

$ConfigKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'

try {
    $config = Get-ItemProperty -Path $ConfigKey

    $productIds = [string]$config.ProductReleaseIds
    $platform   = [string]$config.Platform

    if ([string]::IsNullOrWhiteSpace($productIds)) {
        exit 1
    }

    $installedProducts = @()
    foreach ($entry in $productIds.Split(',')) {
        $trimmed = $entry.Trim()
        if ($trimmed.Length -gt 0) {
            $installedProducts += $trimmed
        }
    }

    if ($installedProducts -notcontains $ExpectedProductId) {
        exit 1
    }

    if ($ExpectedPlatform.Length -gt 0 -and $platform -ne $ExpectedPlatform) {
        exit 1
    }

    Write-Output ("Detected {0} platform {1}" -f $ExpectedProductId, $platform)
    exit 0
}
catch {
    # Silent by design. Any output here would land on STDERR and Intune would
    # read the app as not installed even with a clean exit code.
    exit 1
}
