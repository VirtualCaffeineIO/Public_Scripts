#Requires -Version 5.1
<#
    Detect-M365Base.ps1
    Intune Win32 custom detection script for the M365-Base package.
    Windows PowerShell 5.1 compatible. No PowerShell 7 syntax is used.

    THE DETECTION CONTRACT, AND WHY THIS SCRIPT IS SHAPED THE WAY IT IS

    Microsoft Learn, "Add, Assign, and Monitor a Win32 App in Microsoft Intune",
    Step 4: the Intune agent reads three things from a detection script. The
    exit code, STDOUT and STDERR. The app counts as INSTALLED only when all of
    the following hold:

        1. the script exits with code 0, AND
        2. STDOUT has data, AND
        3. nothing at all was written to STDERR.

    Exit 0 with empty STDOUT means NOT installed. Exit 0 with data on STDOUT
    but anything on STDERR also means NOT installed. Any non-zero exit means
    NOT installed.

    That is the exact failure the previous package hit. Its detection script
    exited 0 and wrote nothing, so Intune read "not installed" on every
    evaluation cycle, reinstalled Office, and did it again roughly 24 hours
    later, forever. Intune re-offers a required app it believes is missing on
    about a 24 hour cadence.

    So, in this script:
      - the success path writes one line and exits 0
      - every failure path exits 1 and writes nothing at all
      - the whole body is wrapped in try/catch and no cmdlet is allowed to emit
        an error record, because an error record reaching STDERR would turn a
        successful detection into a failed one

    WHY REGISTRY AND NOT FILE VERSION

    File version detection breaks the moment the channel delivers an update.
    The binaries move, the detection rule no longer matches, and Intune decides
    a working install is missing. Product presence in the Click-to-Run
    configuration key does not change when the build number changes, which is
    the property you actually want.

    VERIFICATION STATUS OF THE REGISTRY PATH

    The key HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration is
    documented on Microsoft Learn, and Learn names the values UpdateChannel,
    CDNBaseUrl, UpdateUrl and UnmanagedUpdateURL under it.

    The value name ProductReleaseIds, used below, is NOT documented on
    Microsoft Learn. It is the value the Click-to-Run client writes to record
    which product IDs are installed, and it is stable in practice, but treat it
    as an observed behaviour rather than a contract. Before you deploy this at
    scale, read the value on one reference device that already has the build
    you are shipping and confirm it contains the product ID you expect. If your
    estate returns something different, change $ExpectedProductId or the
    parsing to match what you actually observe. Do not assume this script is
    correct for your estate because it is correct for the worked example.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Worked example estate. Substitute your own values.
#   Product   : Microsoft 365 Apps for enterprise
#   Platform  : 64-bit
# If your tenant uses the standalone "Microsoft 365 Apps for enterprise" plan
# or a "(no Teams)" plan, the product ID is O365ProPlusEEANoTeamsRetail and this
# value must change to match the install XML. The install XML and this script
# must always name the same product ID.
# ---------------------------------------------------------------------------
$ExpectedProductId = 'O365ProPlusRetail'
$ExpectedPlatform  = 'x64'

$ConfigKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'

try {
    # Get-ItemProperty throws if the key is absent. That is caught below and
    # treated as not installed, which is correct: no Click-to-Run key means no
    # Click-to-Run Office.
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

    # Architecture check. A 32-bit Office on a device this package targets is a
    # different install that this package cannot service in place, because the
    # ODT refuses to mix architectures. Reporting it as not installed is the
    # honest answer and surfaces it in Intune rather than hiding it.
    if ($ExpectedPlatform.Length -gt 0 -and $platform -ne $ExpectedPlatform) {
        exit 1
    }

    # Success. One line to STDOUT, then exit 0. Both are required.
    Write-Output ("Detected {0} platform {1}" -f $ExpectedProductId, $platform)
    exit 0
}
catch {
    # Deliberately silent. Writing the exception here would put data on STDERR,
    # and Intune treats any STDERR output as not detected even alongside a
    # clean exit code. Silence plus exit 1 is the correct not-installed signal.
    exit 1
}
