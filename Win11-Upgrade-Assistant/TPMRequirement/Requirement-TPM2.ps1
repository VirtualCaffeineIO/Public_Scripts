$tpmInfo = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction SilentlyContinue

if ($tpmInfo -and ($tpmInfo.SpecVersion -match "^2\.0|2\.1")) {
    Write-Host "TPM 2.0 or 2.1 detected"
    exit 0
} else {
    Write-Host "TPM 2.0 or 2.1 not found"
    exit 1
}