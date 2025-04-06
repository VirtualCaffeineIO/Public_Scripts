# Requirement rule: checks for TPM 2.0 or higher
$tpm = Get-WmiObject -Namespace "Root\CIMV2\Security\MicrosoftTpm" -Class Win32_Tpm
if ($tpm -and $tpm.SpecVersion -match "^2\.[0-9]") {
    exit 0
}
exit 1
