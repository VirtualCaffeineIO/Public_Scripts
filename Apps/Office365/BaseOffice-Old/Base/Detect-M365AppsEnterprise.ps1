# Detect-M365AppsEnterprise.ps1
# Exit 0 = detected (installed)
# Exit 1 = not detected (install needed)

$regPath = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'

if (-not (Test-Path $regPath)) {
    exit 1
}

try {
    $cfg = Get-ItemProperty -Path $regPath -ErrorAction Stop
} catch {
    exit 1
}

$productIds = [string]($cfg.ProductReleaseIds)

if ([string]::IsNullOrWhiteSpace($productIds)) {
    exit 1
}

# Desired SKU (what you want)
$want = 'O365ProPlusRetail'

# Common OEM / consumer SKUs that should force a reinstall/cleanup
$oemSkus = @(
    'HomeStudent2021Retail',
    'HomeBusiness2021Retail',
    'O365HomePremRetail',
    'O365HomePremRetailTrial',
    'HomeStudent2019Retail',
    'HomeBusiness2019Retail'
)

# If any OEM SKU exists, force install to run (so your XML can remove/replace it)
foreach ($sku in $oemSkus) {
    if ($productIds -match [regex]::Escape($sku)) {
        exit 1
    }
}

# If the desired SKU exists, we are good
if ($productIds -match [regex]::Escape($want)) {
    exit 0
}

# Otherwise, run install
exit 1
