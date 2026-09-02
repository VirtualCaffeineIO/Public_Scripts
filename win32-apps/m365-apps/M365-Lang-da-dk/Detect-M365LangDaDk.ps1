#Requires -Version 5.1
<#
    Detect-M365LangDaDk.ps1
    Intune Win32 custom detection script for the M365-Lang-da-dk package.
    Windows PowerShell 5.1 compatible.

    Detects the Danish (Denmark) language pack, da-dk.

    da-dk is the worked example for this folder and it runs consistently
    through all three files: install-M365-Lang-da-dk.xml,
    uninstall-M365-Lang-da-dk.xml and this script. The previous package had a
    readme showing da-dk, an XML installing es-ES and a detection script
    checking ja-JP, which meant it installed Spanish, then looked for Japanese,
    never found it, and reinstalled Spanish on every evaluation cycle. To offer
    another language, copy the folder and change the culture code in all three
    files together.

    THE DETECTION CONTRACT

    Per Microsoft Learn, "Add, Assign, and Monitor a Win32 App in Microsoft
    Intune", Step 4: the Intune agent reads the exit code, STDOUT and STDERR.
    The app is INSTALLED only when the script exits 0 AND writes data to STDOUT
    AND writes nothing to STDERR. Exit 0 with empty STDOUT means NOT installed.
    Anything on STDERR means NOT installed even alongside exit code 0.

    Success path: one line to STDOUT, exit 0.
    Every failure path: no output at all, exit 1.
    try/catch around the body so no error record can reach STDERR. Every
    registry read below uses -ErrorAction SilentlyContinue for the same reason,
    because a missing key on a device that legitimately has the language pack
    under the other key must not turn into an error record.

    WHY REGISTRY AND NOT FILE VERSION

    File version detection breaks on the next channel update. Language presence
    does not change when the build number changes.

    VERIFICATION STATUS, READ THIS

    This is the weakest link in the package set and it deserves an honest note.

    HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration is documented on
    Microsoft Learn, which names UpdateChannel, CDNBaseUrl, UpdateUrl and
    UnmanagedUpdateURL under it. Microsoft Learn does NOT document any registry
    value that lists installed Office language packs. Not under the
    Click-to-Run configuration key, and not under LanguageResources.

    So the two locations checked below are observed behaviour, not a documented
    contract. The script scans string values under the Click-to-Run
    configuration key for the culture token, and also checks InstalledUIs under
    the Office 16.0 LanguageResources key. Either hit counts as detected.

    Before you deploy this, install da-dk by hand on one reference device and
    read both locations to confirm which one your build actually populates and
    in what form. If neither is populated in your estate, replace the logic
    with whatever your reference device does expose. Do not ship this on the
    assumption that it is right because it is written down here.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Worked example estate. Substitute your own value.
#   Culture : da-dk, Danish (Denmark)
# This value must match the Language ID in both XML files in this folder.
# Culture codes come from the supported language table on Microsoft Learn.
# Comparison below is case insensitive, so da-dk and da-DK both match.
# ---------------------------------------------------------------------------
$ExpectedCulture = 'da-dk'

$ConfigKey = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
$LangKey   = 'HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\LanguageResources'

try {
    $pattern = [regex]::Escape($ExpectedCulture)
    $found   = $false

    # Location 1: string values under the Click-to-Run configuration key.
    # The culture is recorded here in more than one value name depending on
    # build, so the value names are not hard-coded. Only string values are
    # examined, and only for the culture token.
    $config = Get-ItemProperty -Path $ConfigKey -ErrorAction SilentlyContinue
    if ($null -ne $config) {
        foreach ($property in $config.PSObject.Properties) {
            # Skip the synthetic PowerShell properties. PSPath and PSParentPath
            # carry the registry path itself, so matching against them would be
            # a false positive waiting to happen the day a culture code appears
            # somewhere in a key name.
            if ($property.Name -like 'PS*') {
                continue
            }
            if ($property.Value -is [string]) {
                if ($property.Value -imatch $pattern) {
                    $found = $true
                    break
                }
            }
        }
    }

    # Location 2: InstalledUIs under LanguageResources.
    if (-not $found) {
        $langResources = Get-ItemProperty -Path $LangKey -ErrorAction SilentlyContinue
        if ($null -ne $langResources) {
            $installedUIs = [string]$langResources.InstalledUIs
            if ($installedUIs -imatch $pattern) {
                $found = $true
            }
        }
    }

    if (-not $found) {
        exit 1
    }

    Write-Output ("Detected Office language pack {0}" -f $ExpectedCulture)
    exit 0
}
catch {
    exit 1
}
