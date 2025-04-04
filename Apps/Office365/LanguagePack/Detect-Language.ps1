# Detection script for ja-JP Language Pack via Uninstall registry key
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$found = $false

# Get all subkeys under Uninstall
Get-ChildItem -Path $regPath | ForEach-Object {
    try {
        $props = Get-ItemProperty -Path $_.PSPath
        if ($props.DisplayName -like "*ja-JP*" -or $props.DisplayName -like "*Japanese*") {
            Write-Output "Found language pack: $($props.DisplayName)"
            $found = $true
        }
    } catch {
        # Skip keys that can't be read
    }
}

if ($found) {
    exit 0  # Success: Language pack is installed
} else {
    exit 1  # Not installed
}
