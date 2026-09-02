<#
.SYNOPSIS
    Automatically manages an Entra ID (Azure AD) security group containing recently enrolled Intune Windows devices.

.DESCRIPTION
    This Azure Automation Runbook connects to Microsoft Graph using an app registration
    and maintains membership in a specified Entra ID group based on device enrollment age.

    Devices enrolled in Intune within the defined MaxAgeDays window are added to the group.
    Devices older than MaxAgeDays are automatically removed.

    The group can be used to assign Windows Update for Business (WUfB) policies,
    ensuring that new devices receive updates or configurations immediately,
    while older devices fall into normal production rings.

.PARAMETER MaxAgeDays
    Defines the maximum enrollment age (in days) for devices to remain in the group.
    Defaults to 24 days.

.AUTHOR
    Virtual Caffeine IO
    Website: https://virtualcaffeine.io

.VERSION
    1.0.0

.REQUIREMENTS
    - Azure Automation Account with PowerShell 7.2 runtime
    - Graph API permissions via App Registration:
        * Device.Read.All
        * DeviceManagementManagedDevices.Read.All
        * Group.ReadWrite.All
    - Three Automation variables:
        * GraphTenantId
        * GraphClientId
        * GraphClientSecret

.EXAMPLE
    # Manually run from Azure Automation
    .\Manage-NewDevices-Group.ps1 -MaxAgeDays 30

.NOTES
    Schedule this runbook daily to keep the group current.
    Typical use: Assign WUfB “Immediate Update” ring to this group.
#>

param(
    [int]$MaxAgeDays = 24
)

# --- CONFIG ---
# "All New Windows Devices" Entra security group (Assigned)
$NewDevicesGroupId = "16db42c2-ae22-4078-b6ce-46f3454b3e95"

# Get app registration details from Automation variables
$tenantId     = Get-AutomationVariable -Name "GraphTenantId"
$clientId     = Get-AutomationVariable -Name "GraphClientId"
$clientSecret = Get-AutomationVariable -Name "GraphClientSecret"

Write-Output ("Using TenantId {0} and ClientId {1}; Secret length: {2}" -f $tenantId, $clientId, ($clientSecret.Length))

# === Helper: Get Graph access token via client credentials ===
function Get-GraphToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )

    $body = @{
        client_id     = $ClientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $ClientSecret
        grant_type    = "client_credentials"
    }

    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

    try {
        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
        return $response.access_token
    }
    catch {
        Write-Error ("FAILED to get Graph token: {0}" -f $_.Exception.Message)
        throw
    }
}

# === Helper: Invoke Graph REST ===
function Invoke-GraphGet {
    param(
        [string]$Uri,
        [string]$Token
    )
    $headers = @{ "Authorization" = "Bearer $Token" }
    return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
}

function Invoke-GraphPost {
    param(
        [string]$Uri,
        [string]$Token,
        [object]$Body
    )
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
    }
    $json = $Body | ConvertTo-Json -Depth 5
    return Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -Body $json
}

function Invoke-GraphDelete {
    param(
        [string]$Uri,
        [string]$Token
    )
    $headers = @{ "Authorization" = "Bearer $Token" }
    Invoke-RestMethod -Method Delete -Uri $Uri -Headers $headers
}

# === Get token ===
$accessToken = Get-GraphToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret
Write-Output "Got Graph access token."

# --- Date / cutoff logic (UTC) ---
$nowUtc             = (Get-Date).ToUniversalTime()
$cutoffDateTimeUtc  = $nowUtc.AddDays(-$MaxAgeDays)
$cutoffFilterDateUtc = $cutoffDateTimeUtc.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
Write-Output ("Cutoff date for new devices (UTC): {0} (filter: enrolledDateTime ge '{1}')" -f $cutoffDateTimeUtc, $cutoffFilterDateUtc)

# === 1) Get Windows, company-owned Intune devices enrolled in the last N days ===
$filter = "operatingSystem eq 'Windows' and managedDeviceOwnerType eq 'company' and enrolledDateTime ge '$cutoffFilterDateUtc'"
$mdUri  = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices`?\$filter=$([uri]::EscapeDataString($filter))&`$select=id,deviceName,enrolledDateTime,azureADDeviceId&`$top=999"

try {
    $managedResult  = Invoke-GraphGet -Uri $mdUri -Token $accessToken
    $managedDevices = @()
    if ($managedResult.value) { $managedDevices += $managedResult.value }
    while ($managedResult.'@odata.nextLink') {
        $managedResult = Invoke-GraphGet -Uri $managedResult.'@odata.nextLink' -Token $accessToken
        if ($managedResult.value) { $managedDevices += $managedResult.value }
    }
    Write-Output ("Found {0} managed devices enrolled since {1} UTC" -f $managedDevices.Count, $cutoffDateTimeUtc)
}
catch {
    Write-Error ("Error calling managedDevices: {0}" -f $_.Exception.Message)
    return
}

# === Helper: get AAD device by Azure AD deviceId ===
function Get-AadDeviceByAzureAdDeviceId {
    param(
        [string]$AzureAdDeviceId,
        [string]$Token
    )

    $uri = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$AzureAdDeviceId'&`$select=id,displayName,deviceId"
    $res = Invoke-GraphGet -Uri $uri -Token $Token
    if ($res.value -and $res.value.Count -gt 0) { return $res.value[0] }
    return $null
}

# === Helper: add device to group ===
function Add-DeviceToNewGroup {
    param(
        [string]$AzureAdDeviceId,
        [string]$Token
    )

    $aadDevice = Get-AadDeviceByAzureAdDeviceId -AzureAdDeviceId $AzureAdDeviceId -Token $Token
    if (-not $aadDevice) {
        Write-Warning ("No Entra device found for AzureADDeviceId {0}" -f $AzureAdDeviceId)
        return
    }

    $dirObjId = $aadDevice.id
    $uri  = "https://graph.microsoft.com/v1.0/groups/$NewDevicesGroupId/members/`$ref"
    $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$dirObjId" }

    try {
        Invoke-GraphPost -Uri $uri -Token $Token -Body $body
        Write-Output ("Added {0} to 'All New Windows Devices'." -f $aadDevice.displayName)
    }
    catch {
        $msg = $_.Exception.Message
        $details = $_.ErrorDetails.Message
        $text = ($msg + " " + $details)
        if ($text -match "added object references already exist" -or $text -match "Response status code does not indicate success: 400") {
            Write-Output ("Device {0} is already in 'All New Windows Devices'." -f $aadDevice.displayName)
        } else {
            Write-Warning ("Failed to add {0} to group: {1}" -f $aadDevice.displayName, $text)
        }
    }
}

# === 2) Ensure all "recent" devices are in group ===
foreach ($md in $managedDevices) {
    if (-not $md.azureADDeviceId) {
        Write-Warning ("Managed device {0} has no azureADDeviceId – skipping." -f $md.deviceName)
        continue
    }

    if ($md.enrolledDateTime) {
        $mdEnrollUtc = ([datetime]$md.enrolledDateTime).ToUniversalTime()
        if ($mdEnrollUtc -lt $cutoffDateTimeUtc) {
            Write-Output ("Skipping {0}; enrolled {1} UTC older than cutoff {2} UTC." -f $md.deviceName, $mdEnrollUtc, $cutoffDateTimeUtc)
            continue
        }
    } else {
        Write-Warning ("Managed device {0} has no enrolledDateTime – skipping." -f $md.deviceName)
        continue
    }

    Write-Output ("Recent candidate: {0} (enrolled {1})" -f $md.deviceName, $md.enrolledDateTime)
    Add-DeviceToNewGroup -AzureAdDeviceId $md.azureADDeviceId -Token $accessToken
}

# === 3) Remove expired devices ===
Write-Output "Checking existing 'All New Windows Devices' members for expiry..."
$membersUri = "https://graph.microsoft.com/v1.0/groups/$NewDevicesGroupId/members/microsoft.graph.device?`$select=id,displayName,deviceId"

try {
    $membersResult = Invoke-GraphGet -Uri $membersUri -Token $accessToken
    $groupMembers  = @()
    if ($membersResult.value) { $groupMembers += $membersResult.value }
    while ($membersResult.'@odata.nextLink') {
        $membersResult = Invoke-GraphGet -Uri $membersResult.'@odata.nextLink' -Token $accessToken
        if ($membersResult.value) { $groupMembers += $membersResult.value }
    }
}
catch {
    Write-Error ("Error getting group members: {0}" -f $_.Exception.Message)
    return
}

foreach ($member in $groupMembers) {
    $dirDeviceId = $member.id
    $aadDevice   = $member

    if (-not $aadDevice.deviceId) {
        Write-Warning ("AAD device {0} has no deviceId – skipping." -f $aadDevice.displayName)
        continue
    }

    try {
        $mdFilter = "azureADDeviceId eq '$($aadDevice.deviceId)'"
        $mdUri2   = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=$([uri]::EscapeDataString($mdFilter))&`$select=enrolledDateTime,deviceName"
        $mdResult = Invoke-GraphGet -Uri $mdUri2 -Token $accessToken
        if (-not $mdResult.value -or $mdResult.value.Count -eq 0) {
            Write-Warning ("No Intune managedDevice found for {0} – skipping." -f $aadDevice.displayName)
            continue
        }
        $md = $mdResult.value[0]
    }
    catch {
        Write-Warning ("Error getting managedDevice for {0}: {1}" -f $aadDevice.displayName, $_.Exception.Message)
        continue
    }

    $enrolledUtc = ([datetime]$md.enrolledDateTime).ToUniversalTime()
    if ($enrolledUtc -lt $cutoffDateTimeUtc) {
        Write-Output ("Device {0} enrolled {1} UTC – removing from group." -f $md.deviceName, $enrolledUtc)
        try {
            $delUri = "https://graph.microsoft.com/v1.0/groups/$NewDevicesGroupId/members/$dirDeviceId/`$ref"
            Invoke-GraphDelete -Uri $delUri -Token $accessToken
        }
        catch {
            Write-Warning ("Failed to remove {0} from group: {1}" -f $aadDevice.displayName, $_.Exception.Message)
        }
    } else {
        Write-Output ("Device {0} still within window (enrolled {1} UTC)." -f $md.deviceName, $enrolledUtc)
    }
}
