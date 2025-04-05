# PowerShell Script to Automate Two-Tier PKI Deployment on Windows Server 2022
# Root CA and Subordinate CA with CRL hosted on crl.localdomain.com

# --- Section 1: Offline Root CA Setup ---
$RootCAName = "TD-RootCA"
$RootCACommonName = "TD-Root-CA"
$RootCADir = "C:\PKI\RootCA"
$RootCAAIADir = "C:\PKI\AIA"
$RootCACDPDir = "C:\PKI\CDP"
$RootCADBDir = "C:\PKI\DB"
$RootCALogDir = "C:\PKI\Logs"
$CAPolicyInf = "$RootCADir\CAPolicy.inf"
$RootCertPath = "$RootCADir\$RootCACommonName.crt"
$CRLPath = "$RootCADir\$RootCACommonName.crl"
$CRLDistPoint = "http://crl.localdomain.com/pki/$RootCACommonName.crl"
$RootDSN = "DC=localdomain,DC=Com"

# Ensure necessary directories exist
$directories = @($RootCADir, $RootCADBDir, $RootCALogDir, $RootCAAIADir, $RootCACDPDir)
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force
    }
}

# Create CAPolicy.inf file with configuration settings for the Root CA
Set-Content -Path $CAPolicyInf -Value @"
[Version]
Signature = "$Windows NT$"

[PolicyStatementExtension]
Policies = AllIssuancePolicy, InternalPolicy
Critical = FALSE

[Certsrv_Server]
; Renewal information for the Root CA.
RenewalKeyLength = 4096
RenewalValidityPeriod = Years
RenewalValidityPeriodUnits = 20
; The CRL publication period is the lifetime of the Root CA.
CRLPeriod = Years
CRLPeriodUnits = 20
; The option for Delta CRL is disabled since this is a Root CA.
CRLDeltaPeriod = days
CRLDeltaPeriodUnits = 0
LoadDefaultTemplates = 0
AlternateSignatureAlgorithm = 0
"@

# Install Active Directory Certificate Services (AD CS) for the Root CA
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

# Configure Root CA with specified settings
Install-AdcsCertificationAuthority `
  -CAType StandaloneRootCA `
  -CACommonName $RootCACommonName `
  -CADistinguishedNameSuffix "$RootDSN" `
  -KeyLength 4096 `
  -HashAlgorithm SHA256 `
  -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
  -ValidityPeriod Years `
  -ValidityPeriodUnits 20 `
  -DatabaseDirectory "$RootCADBDir" `
  -LogDirectory "$RootCALogDir" `
  -Force

# Remove all existing AIA and CDP entries
certutil -delreg CA\CRLPublicationURLs
certutil -delreg CA\CACertPublicationURLs

# Configure CDP (CRL Distribution Point) and AIA (Authority Information Access) with proper variable substitutions
# CDP Publication URLs
certutil -setreg CA\CRLPublicationURLs "65:C:\PKI\CDP\%3%8.crl\n6:http://crl.localdomain.com/pki/%3%8.crl"
# AIA Publication URLs
certutil -setreg CA\CACertPublicationURLs "1:C:\PKI\AIA\3%4%.crt\n2:http://crl.localdomain.com/pki/3%4%.crt"
## Important ##
## You must go uncheck delta CRL's the script cant do that part

# Configure additional Root CA settings
certutil -setreg CA\DSConfigDN "CN=Configuration,DC=localdomain,DC=com"
certutil -setreg CA\CRLPeriodUnits 1
certutil -setreg CA\CRLPeriod "Year"
certutil -setreg CA\CRLOverlapUnits 8
certutil -setreg CA\CRLOverlapPeriod "Weeks"
certutil -setreg CA\ValidityPeriodUnits 5
certutil -setreg CA\ValidityPeriod "Years"
# Enable Auditing on the CA for all events
certutil.exe -setreg CA\AuditFilter 127

# Restart the CA service to apply changes
Restart-Service CertSvc

# Publish the initial Certificate Revocation List (CRL)
certutil -crl

###
# Also publish the RootCA.crt to the domain
# From a Domain Joined PC
# Certutil -dspublish -f <RootCA.crt> RootCA
###

###
# Copy root CA and CRL to Web Servers 
# C:\PKI\CSJ-Root-CA.crt
# C:\PKI\CSJ-Root-CA.crl

# Export Root CA Certificate for distribution
certutil -ca.cert "$RootCertPath"

# --- Section 2: Subordinate CA Setup ---
$SubCAName = "TD-SubCA.localdomain.com"
$SubCACommonName = "TD-Subordinate-CA"
$SubCADir = "C:\PKI\SubCA"
$SubCADBDir = "C:\PKI\DB"
$SubCAPolicyInf = "$SubCADir\CAPolicy.inf"
$SubCACertReq = "$SubCADir\$SubCACommonName.req"
$SubCAAIADir = "C:\PKI\AIA"
$SubCACDPDir = "C:\PKI\CDP"
$SubCALogDir = "C:\PKI\Logs"

# Ensure necessary directories exist
$directories = @($SubCADir, $SubCADBDir, $SubCALogDir, $SubCAAIADir, $SubCACDPDir)
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force
    }
}

# Create CAPolicy.inf for Subordinate CA
Set-Content -Path $SubCAPolicyInf -Value @"
[Version]
Signature = "$Windows NT$"

[PolicyStatementExtension]
Policies = AllIssuancePolicy, InternalPolicy
Critical = FALSE

[Certsrv_Server]
;  Renewal information for the Subordinate CA
RenewalKeyLength = 4096
RenewalValidityPeriod = Years
RenewalValidityPeriodUnits = 5

; Disable support for issuing certificates using RSASSA-PSS.
AlternateSignatureAlgorithm = 0
; Load all certificate templates by default.
LoadDefaultTemplates = 1
"@

# Install AD CS Role for Subordinate CA
Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools

# Configure Subordinate CA
Install-AdcsCertificationAuthority `
  -CAType EnterpriseSubordinateCA `
  -CACommonName $SubCACommonName `
  -KeyLength 4096 `
  -HashAlgorithm SHA256 `
  -DatabaseDirectory "$SubCADBDir" `
  -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
  -Force

# Generate Certificate Signing Request (CSR) for Subordinate CA
certreq -new $SubCAPolicyInf $SubCACertReq

Write-Host "Subordinate CA certificate request generated. Please sign it using the Root CA and import the signed certificate."


