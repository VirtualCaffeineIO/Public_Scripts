#Requires -Version 5.1
<#
    Detect-M365Project.ps1
    Intune Win32 custom detection script for the M365-Project package.
    Windows PowerShell 5.1 compatible.

    THE DETECTION CONTRACT

    Per Microsoft Learn, "Add, Assign, and Monitor a Win32 App in Microsoft
    Intune", Step 4: the Intune agent reads the exit code, STDOUT and STDERR.
    The app is INSTALLED only when the script exits 0 AND writes data to STDOUT
    AND writes nothing to STDERR. Exit 0 with empty STDOUT means NOT installed.
    Anything on STDERR means NOT installed even alongside exit code 0.

    Success path: one line to STDOUT, exit 0.
    Every failure path: no output at all, exit 1.
    try/catch around the body so no error record can reach STDERR.

    WHY REGISTRY AND NOT FILE VERSION

    File version detection breaks on the next channel update. Product presence
    does not change when the build number changes.

    NO ARCHITECTURE CHECK HERE, ON PURPOSE

    The install XML omits OfficeClientEdition so the ODT matches the existing
    install. A detection script that demanded x64 would report a correctly
    installed Project on a 32-bit Office device as missing and reinstall it
    forever.

    VERIFICATION STATUS

    HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration is documented on
    Microsoft Learn. The value name ProductReleaseIds is NOT documented on
    Learn. Confirm it on a reference device before trusting this at scale.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Worked example estate. Substitute your own value.
#   Product : Project desktop app from Planner and Project Plan 3 or Plan 5
#
# Microsoft Learn lists ProjectProRetail as the supported ODT product ID for
# the subscription Project desktop app, and does not distinguish between Plan 3
# and Plan 5 at the product ID level. The plan difference is a licensing and
# service plan difference, not a different installer. Learn's licensing
# reference shows both plans carrying the same PROJECT_CLIENT_SUBSCRIPTION
# service plan, "Project Online Desktop Client".
#
# If you deploy a volume licensed Project LTSC instead, the product ID is
# different (for example ProjectPro2024Volume) and this value and the install
# XML must both change to match.
# ---------------------------------------------------------------------------
$ExpectedProductId = 'ProjectProRetail'

$ConfigKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'

try {
    $config = Get-ItemProperty -Path $ConfigKey

    $productIds = [string]$config.ProductReleaseIds

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

    Write-Output ("Detected {0}" -f $ExpectedProductId)
    exit 0
}
catch {
    exit 1
}
