<#
.SYNOPSIS
    Resets the Windows logon LastUsedCredentialProvider
    to the Password Credential Provider GUID.

.DESCRIPTION
    When Web Sign-In or Temporary Access Pass is used, Windows can
    remember those credential providers as "last used" and show them
    first at the logon screen, even if policy sets the default provider
    to password.

    This script forces the LastUsedCredentialProvider (and optionally
    DefaultCredentialProvider) to the Password Credential Provider GUID
    so that classic username/password appears as the default.

    Intended for use as an Intune remediation script.

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
        New-Item -Path $regPath -Force | Out-Null
    }

    # Force LastUsedCredentialProvider to password provider
    Set-ItemProperty -Path $regPath -Name 'LastUsedCredentialProvider' -Value $PasswordProviderGuid -Force

    # Optional: also enforce DefaultCredentialProvider to the same GUID
    # (Intune policy should already do this, but this keeps the value aligned.)
    Set-ItemProperty -Path $regPath -Name 'DefaultCredentialProvider' -Value $PasswordProviderGuid -Force

    Write-Output "Successfully set LastUsedCredentialProvider and DefaultCredentialProvider to $PasswordProviderGuid."
    exit 0
}
catch {
    Write-Output "Failed to set credential provider: $($_.Exception.Message)"
    exit 1
}
