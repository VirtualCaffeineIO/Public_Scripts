# Get the domain name of the computer
$DomainName = (Get-WmiObject Win32_ComputerSystem).Domain

# Define domain-based group names
$DomainAdminsGroup = "$DomainName\Domain Admins"
$CertPublishersGroup = "$DomainName\Cert Publishers"

# Define other variables
$SiteName = "Default Web Site"
$VirtualDirName = "pki"
$PhysicalPath = "C:\pki"
$AppPoolUser = "IIS AppPool\DefaultAppPool"
$ShareName = "PKI"

Write-Host "Using domain: $DomainName"
Write-Host "Domain Admins Group: $DomainAdminsGroup"
Write-Host "Cert Publishers Group: $CertPublishersGroup"

# Check if the PKI directory exists, if not create it
if (!(Test-Path $PhysicalPath)) {
    Write-Host "C:\PKI does not exist. Creating it now..."
    New-Item -Path $PhysicalPath -ItemType Directory -Force
} else {
    Write-Host "C:\PKI already exists. Proceeding with configuration..."
}

# Install IIS if not already installed
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Set NTFS permissions - Read & Execute for DefaultAppPool
$Acl = Get-Acl $PhysicalPath
$AppPoolRule = New-Object System.Security.AccessControl.FileSystemAccessRule($AppPoolUser, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($AppPoolRule)

# Set NTFS permissions - Modify for Domain-based Cert Publishers
$CertPublishersRule = New-Object System.Security.AccessControl.FileSystemAccessRule($CertPublishersGroup, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($CertPublishersRule)

# Set NTFS permissions - Full Control for Domain-based Domain Admins
$DomainAdminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule($DomainAdminsGroup, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$Acl.SetAccessRule($DomainAdminsRule)

# Apply the NTFS ACL changes
Set-Acl -Path $PhysicalPath -AclObject $Acl

# Create the virtual directory under the Default Web Site (if it doesn't exist)
if (!(Get-WebVirtualDirectory -Site $SiteName -Name $VirtualDirName -ErrorAction SilentlyContinue)) {
    New-WebVirtualDirectory -Site $SiteName -Name $VirtualDirName -PhysicalPath $PhysicalPath
    Write-Host "Virtual directory 'pki' created."
} else {
    Write-Host "Virtual directory 'pki' already exists."
}

# Enable Directory Browsing for the "pki" virtual directory
Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -Name "enabled" -Value "True" -PSPath "IIS:\Sites\$SiteName\$VirtualDirName"

# Enable double escaping
Set-WebConfigurationProperty -Filter "/system.webServer/security/requestFiltering" -Name "allowDoubleEscaping" -Value "True" -PSPath "IIS:\Sites\$SiteName"

# Share the folder with Domain Admins and Cert Publishers (if not already shared)
if (!(Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $ShareName -Path $PhysicalPath -FullAccess "$DomainAdminsGroup", "$CertPublishersGroup"
    Write-Host "C:\PKI shared as \\$env:COMPUTERNAME\$ShareName with Domain Admins and Cert Publishers."
} else {
    Write-Host "C:\PKI is already shared."
}

# Restart IIS to apply changes
Restart-Service W3SVC

Write-Host "IIS configuration for 'pki' virtual directory is complete."
Write-Host "Double escaping is enabled."
Write-Host "DefaultAppPool has Read & Execute permissions."
Write-Host "Cert Publishers group ($CertPublishersGroup) has Modify permissions."
Write-Host "Domain Admins group ($DomainAdminsGroup) has Full Control."
Write-Host "C:\PKI is shared and accessible."
