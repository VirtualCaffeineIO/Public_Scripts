#Requires -Version 5.1
<#
    Detect-M365Visio.ps1
    Intune Win32 custom detection script for the M365-Visio package.
    Windows PowerShell 5.1 compatible.

    THE DETECTION CONTRACT

    Per Microsoft Learn, "Add, Assign, and Monitor a Win32 App in Microsoft
    Intune", Step 4: the Intune agent reads the exit code, STDOUT and STDERR.
    The app is INSTALLED only when the script exits 0 AND writes data to STDOUT
    AND writes nothing to STDERR. Exit 0 with empty STDOUT means NOT installed.
    Anything on STDERR means NOT installed even with exit code 0.

    Success path: one line to STDOUT, exit 0.
    Every failure path: no output at all, exit 1.
    try/catch around the body so no error record can reach STDERR.

    WHY REGISTRY AND NOT FILE VERSION

    File version detection breaks on the next channel update, because the
    binaries change and the rule stops matching a perfectly good install.
    Product presence does not change when the build number changes.

    NO ARCHITECTURE CHECK HERE, ON PURPOSE

    The install XML omits OfficeClientEdition so the ODT matches whatever
    architecture the base install already uses. If the detection script then
    demanded x64 it would report a correctly installed Visio on a 32-bit Office
    device as missing, and Intune would reinstall it forever. The package is
    universal across architectures, so the detection has to be too.

    VERIFICATION STATUS

    HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration is documented on
    Microsoft Learn. The value name ProductReleaseIds is NOT documented on
    Learn. Confirm it on a reference device before trusting this at scale.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Worked example estate. Substitute your own value.
#   Product : Visio desktop app from a Visio Plan 2 subscription
#
# Microsoft Learn lists VisioProRetail as the supported ODT product ID for the
# subscription Visio desktop app. If you deploy a volume licensed Visio LTSC
# instead, the product ID is different (for example VisioPro2024Volume) and
# this value and the install XML must both change to match.
# ---------------------------------------------------------------------------
$ExpectedProductId = 'VisioProRetail'

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
