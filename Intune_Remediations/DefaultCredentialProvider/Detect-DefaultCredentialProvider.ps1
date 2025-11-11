<#
.SYNOPSIS
    Detects whether the Windows logon "LastUsedCredentialProvider"
    is set to the Password Credential Provider.

.DESCRIPTION
    Some environments enable Web Sign-In / Temporary Access Pass (TAP)
    but want the default credential provider to remain the classic
    username/password provider.

    Windows can remember the last-used provider and prefer it on
    subsequent sign-ins, even when a policy sets the default provider.
    This script checks whether the last-used provider GUID matches
    the Password Credential Provider GUID.

    If the provider is not set to the Password provider, the script
    returns a non-zero exit code for Intune remediation.

.AUTHOR
    Virtual Caffeine IO

.WEBSITE
    https://virtualcaffeine.io
#>

param()

# Password credential provider GUID (PasswordCredentialProvider)
$PasswordProviderGuid = '{60b78e88-ead8-445c-9cfd-0b87f74ea6cd}'

$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'

try {
    if (-not (Test-Path -Path $regPath)) {
        Write-Output "Registry path not found: $regPath"
        # Treat as non-compliant so remediation can repair
        exit 1
    }

    $props = Get-ItemProperty -Path $regPath -ErrorAction Stop

    $lastUsed = $props.LastUsedCredentialProvider

    if ([string]::IsNullOrWhiteSpace($lastUsed)) {
        Write-Output "LastUsedCredentialProvider is not set. Non-compliant."
        exit 1
    }

    if ($lastUsed.Trim().ToLower() -eq $PasswordProviderGuid.ToLower()) {
        Write-Output "Compliant: LastUsedCredentialProvider is set to the Password provider ($lastUsed)."
        exit 0
    }
    else {
        Write-Output "Non-compliant: LastUsedCredentialProvider is '$lastUsed' (expected $PasswordProviderGuid)."
        exit 1
    }
}
catch {
    Write-Output "Error checking credential provider: $($_.Exception.Message)"
    # Fail closed so remediation runs
    exit 1
}
