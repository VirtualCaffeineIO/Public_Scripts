<#
.SYNOPSIS
Creates or audits a reusable Microsoft Intune and Windows Autopilot tenant foundation.

.DESCRIPTION
Report-only is the default. Supply -Apply to create missing objects. Existing objects
are never updated or deleted: configuration drift is reported for administrator review.

The package creates or audits:
- Microsoft Intune Enrollment service principal
- Dynamic Microsoft Entra device groups
- Windows Autopilot deployment profiles and assignments
- Intune device assignment filters
- Windows Enrollment Status Page profiles and assignments

.EXAMPLE
./Invoke-IntuneTenantBootstrap.ps1 -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -ReportOnly

.EXAMPLE
./Invoke-IntuneTenantBootstrap.ps1 -TenantId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' -Apply
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Report')]
param(
    [Parameter(Mandatory)]
    [guid]$TenantId,

    [Parameter(ParameterSetName = 'Report')]
    [switch]$ReportOnly,

    [Parameter(Mandatory, ParameterSetName = 'Apply')]
    [switch]$Apply,

    [Parameter()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ConfigurationPath = (Join-Path $PSScriptRoot 'IntuneTenantBootstrap.psd1'),

    [switch]$UseDeviceCodeAuth,
    [switch]$InstallGraphModules,

    [string]$LogDirectory = (Join-Path ([System.IO.Path]::GetTempPath()) 'IntuneTenantBootstrapLogs')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Configuration = $null
$script:WriteMode = $Apply.IsPresent
$script:Summary = [System.Collections.Generic.List[object]]::new()
$script:TranscriptStarted = $false
$script:RunTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:GraphV1 = 'https://graph.microsoft.com/v1.0'
$script:GraphBeta = 'https://graph.microsoft.com/beta'
$script:ResolvedBlockingAppIds = @()
$script:DynamicGroupDefinitions = @()
$script:AutopilotProfileDefinitions = @()
$script:DeviceFilterDefinitions = @()
$script:EspDefinitions = @()

function Write-InfoMessage { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-OkMessage   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-WarnMessage { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-FailMessage { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Add-Summary {
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Status,
        [string]$Notes = ''
    )

    $script:Summary.Add([pscustomobject]@{
        Type = $Type
        Name = $Name
        Action = $Action
        Status = $Status
        Notes = $Notes
    }) | Out-Null
}

function ConvertTo-NormalizedText {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return '' }
    return (([string]$Value -replace "`r`n", "`n") -replace "`r", "`n").Trim()
}

function Get-ObjectPropertyValue {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) { return $InputObject[$Name] }
        return $null
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Test-EquivalentCollection {
    param([AllowNull()][object[]]$Actual, [AllowNull()][object[]]$Expected)
    $left = @($Actual | ForEach-Object { [string]$_ } | Sort-Object)
    $right = @($Expected | ForEach-Object { [string]$_ } | Sort-Object)
    return (($left | ConvertTo-Json -Compress) -eq ($right | ConvertTo-Json -Compress))
}

function ConvertTo-ODataLiteral {
    param([Parameter(Mandatory)][string]$Value)
    return $Value.Replace("'", "''")
}

function Assert-UniqueName {
    param([Parameter(Mandatory)][string[]]$Names, [Parameter(Mandatory)][string]$Category)
    $duplicates = $Names | Group-Object | Where-Object Count -gt 1
    if ($duplicates) {
        throw "$Category contains duplicate names: $($duplicates.Name -join ', ')"
    }
    if ($Names | Where-Object { [string]::IsNullOrWhiteSpace($_) }) {
        throw "$Category contains an empty name."
    }
}

function Import-AndValidateConfiguration {
    Write-InfoMessage "Loading configuration: $ConfigurationPath"
    $script:Configuration = Import-PowerShellDataFile -LiteralPath $ConfigurationPath

    if ($script:Configuration.SchemaVersion -ne '1.1') {
        throw "Unsupported configuration schema [$($script:Configuration.SchemaVersion)]. Expected [1.1]."
    }

    $n = $script:Configuration.Naming
    Assert-UniqueName -Category 'Dynamic group names' -Names @(
        $n.PilotTagGroup, $n.ProductionTagGroup, $n.AllAutopilotGroup, $n.ExistingDeviceIntakeGroup
    )
    Assert-UniqueName -Category 'Autopilot profile names' -Names @(
        $n.PilotProfile, $n.ProductionProfile, $n.ExistingDeviceProfile
    )
    Assert-UniqueName -Category 'Assignment filter names' -Names @(
        $n.PilotFilter, $n.ProductionFilter, $n.CombinedFilter
    )
    Assert-UniqueName -Category 'ESP profile names' -Names @($n.PilotEsp, $n.ProductionEsp)

    if (-not $script:Configuration.ExistingDeviceIntake.CompanyOwnedDevicesOnly) {
        throw 'CompanyOwnedDevicesOnly must remain enabled in schema version 1.1.'
    }

    $espPriorities = @([int]$script:Configuration.Esp.PilotPriority, [int]$script:Configuration.Esp.ProductionPriority)
    if ($espPriorities[0] -eq $espPriorities[1]) {
        throw "Esp.PilotPriority and Esp.ProductionPriority must differ; both are [$($espPriorities[0])]."
    }
    foreach ($priority in $espPriorities) {
        if ($priority -lt 1) {
            throw "ESP priority [$priority] is invalid. Priority 0 belongs to the built-in default profile."
        }
    }

    $blockingNames = @($script:Configuration.Esp.BlockingAppDisplayNames)
    if ($blockingNames.Count -gt 0) {
        Assert-UniqueName -Category 'ESP blocking application names' -Names $blockingNames
    }

    $script:DynamicGroupDefinitions = @(
        @{
            DisplayName = $n.PilotTagGroup
            Description = "Autopilot Group Tag for Windows 11 Microsoft Entra pilot devices: $($n.PilotTag)"
            MembershipRule = "(device.devicePhysicalIds -any (_ -eq `"[OrderID]:$($n.PilotTag)`"))"
        },
        @{
            DisplayName = $n.ProductionTagGroup
            Description = "Autopilot Group Tag for Windows 11 Microsoft Entra production devices: $($n.ProductionTag)"
            MembershipRule = "(device.devicePhysicalIds -any (_ -eq `"[OrderID]:$($n.ProductionTag)`"))"
        },
        @{
            DisplayName = $n.AllAutopilotGroup
            Description = 'All company-owned Windows Autopilot devices'
            MembershipRule = '(device.deviceOwnership -eq "Company") and (device.devicePhysicalIds -any (_ -startsWith "[ZTDId]"))'
        },
        @{
            DisplayName = $n.ExistingDeviceIntakeGroup
            Description = 'Real-time intake group that registers company-owned, Intune-managed Windows devices in Autopilot and releases them after [ZTDId] appears'
            MembershipRule = '(device.deviceOSType -eq "Windows") and (device.managementType -eq "MDM") and (device.deviceOwnership -eq "Company") and (device.devicePhysicalIds -all (_ -notContains "[ZTDId]"))'
        }
    )

    $script:AutopilotProfileDefinitions = @(
        @{
            DisplayName = $n.PilotProfile
            Description = "Windows Autopilot deployment profile for pilot devices. The profile name is referenced by assignment filters."
            AssignedGroupName = $n.PilotTagGroup
            DeviceNameTemplate = $script:Configuration.Autopilot.DeviceNameTemplate
            PreprovisioningAllowed = [bool]$script:Configuration.Autopilot.EnablePreprovisioning
        },
        @{
            DisplayName = $n.ProductionProfile
            Description = "Windows Autopilot deployment profile for production devices. The profile name is referenced by assignment filters."
            AssignedGroupName = $n.ProductionTagGroup
            DeviceNameTemplate = $script:Configuration.Autopilot.DeviceNameTemplate
            PreprovisioningAllowed = [bool]$script:Configuration.Autopilot.EnablePreprovisioning
        }
    )

    if ($script:Configuration.ExistingDeviceIntake.Enabled) {
        $script:AutopilotProfileDefinitions += @{
            DisplayName = $n.ExistingDeviceProfile
            Description = 'Registers eligible existing Intune-managed Windows devices in Autopilot without assigning an OrderID Group Tag'
            AssignedGroupName = $n.ExistingDeviceIntakeGroup
            DeviceNameTemplate = ''
            PreprovisioningAllowed = $false
        }
    }

    # Filter rules are generated from the canonical profile names, eliminating
    # singular/plural or spelling drift between filters and profiles.
    $script:DeviceFilterDefinitions = @(
        @{
            DisplayName = $n.PilotFilter
            Description = "Devices enrolled through the [$($n.PilotProfile)] Autopilot profile"
            Platform = 'windows10AndLater'
            Rule = "(device.enrollmentProfileName -eq `"$($n.PilotProfile)`")"
        },
        @{
            DisplayName = $n.ProductionFilter
            Description = "Devices enrolled through the [$($n.ProductionProfile)] Autopilot profile"
            Platform = 'windows10AndLater'
            Rule = "(device.enrollmentProfileName -eq `"$($n.ProductionProfile)`")"
        },
        @{
            DisplayName = $n.CombinedFilter
            Description = "Devices enrolled through either [$($n.PilotProfile)] or [$($n.ProductionProfile)]"
            Platform = 'windows10AndLater'
            Rule = "(device.enrollmentProfileName -eq `"$($n.PilotProfile)`") or (device.enrollmentProfileName -eq `"$($n.ProductionProfile)`")"
        }
    )

    $script:EspDefinitions = @(
        @{
            DisplayName = $n.PilotEsp
            Description = "Fail-open Enrollment Status Page for devices in [$($n.PilotTagGroup)]"
            AssignedGroupName = $n.PilotTagGroup
            Priority = [int]$script:Configuration.Esp.PilotPriority
        },
        @{
            DisplayName = $n.ProductionEsp
            Description = "Fail-open Enrollment Status Page for devices in [$($n.ProductionTagGroup)]"
            AssignedGroupName = $n.ProductionTagGroup
            Priority = [int]$script:Configuration.Esp.ProductionPriority
        }
    )

    Write-OkMessage 'Configuration validation passed.'
}

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7 or later is required. Current version: $($PSVersionTable.PSVersion)"
    }
}

function Initialize-GraphAuthenticationModule {
    $minimum = [version]$script:Configuration.Graph.MinimumModuleVersion
    $installed = Get-Module -ListAvailable Microsoft.Graph.Authentication |
        Sort-Object Version -Descending | Select-Object -First 1

    if (-not $installed -or $installed.Version -lt $minimum) {
        if (-not $InstallGraphModules) {
            throw "Microsoft.Graph.Authentication $minimum or later is required. Rerun with -InstallGraphModules to install it for the current user."
        }
        Write-InfoMessage "Installing Microsoft.Graph.Authentication $minimum or later for the current user..."
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -MinimumVersion $minimum -Force -AllowClobber
    }

    Import-Module Microsoft.Graph.Authentication -MinimumVersion $minimum -Force
    Write-OkMessage "Microsoft.Graph.Authentication $((Get-Module Microsoft.Graph.Authentication).Version) loaded."
}

function Start-PackageLogging {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Writes only to the operator-supplied log directory; the tenant confirmation covers the run.')]
    param()

    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    $transcriptPath = Join-Path $LogDirectory "IntuneTenantBootstrap-$script:RunTimestamp.log"
    try {
        Start-Transcript -LiteralPath $transcriptPath -Force | Out-Null
        $script:TranscriptStarted = $true
        Write-InfoMessage "Transcript: $transcriptPath"
    }
    catch {
        Write-WarnMessage "Transcript could not be started: $($_.Exception.Message)"
    }
}

function Export-PackageSummary {
    if (-not (Test-Path -LiteralPath $LogDirectory)) { return }
    $base = Join-Path $LogDirectory "IntuneTenantBootstrap-$script:RunTimestamp-summary"
    @($script:Summary) | Export-Csv -LiteralPath "$base.csv" -NoTypeInformation -Force
    @($script:Summary) | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath "$base.json" -Encoding utf8
    Write-InfoMessage "Summary: $base.csv"
}

function Get-GraphScope {
    param([switch]$RequireApplicationWrite)

    $scopes = [System.Collections.Generic.List[string]]::new()
    if ($script:WriteMode) {
        $scopes.Add('Group.ReadWrite.All')
        $scopes.Add('DeviceManagementServiceConfig.ReadWrite.All')
        $scopes.Add('DeviceManagementConfiguration.ReadWrite.All')
    }
    else {
        $scopes.Add('Group.Read.All')
        $scopes.Add('DeviceManagementServiceConfig.Read.All')
        $scopes.Add('DeviceManagementConfiguration.Read.All')
    }

    if ($RequireApplicationWrite) { $scopes.Add('Application.ReadWrite.All') }
    else { $scopes.Add('Application.Read.All') }

    if (@($script:Configuration.Esp.BlockingAppDisplayNames).Count -gt 0) {
        $scopes.Add('DeviceManagementApps.Read.All')
    }

    return @($scopes | Sort-Object -Unique)
}

function Connect-ValidatedGraph {
    param([switch]$RequireApplicationWrite)

    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }
    $scopes = Get-GraphScope -RequireApplicationWrite:$RequireApplicationWrite
    Write-InfoMessage "Connecting to tenant [$TenantId]..."

    $parameters = @{
        TenantId = $TenantId.Guid
        Scopes = $scopes
        ContextScope = 'Process'
        NoWelcome = $true
    }
    if ($UseDeviceCodeAuth) { $parameters.UseDeviceAuthentication = $true }
    Connect-MgGraph @parameters

    $context = Get-MgContext
    if (-not $context) { throw 'Microsoft Graph authentication did not return a context.' }
    if ([guid]$context.TenantId -ne $TenantId) {
        throw "Authenticated tenant [$($context.TenantId)] does not match requested tenant [$TenantId]."
    }

    Write-OkMessage "Authenticated account: $($context.Account)"
    Write-OkMessage "Verified tenant ID: $($context.TenantId)"
    return $context
}

function Get-HttpStatusCode {
    param([Parameter(Mandatory)][object]$Exception)
    $response = Get-ObjectPropertyValue -InputObject $Exception -Name 'Response'
    foreach ($candidate in @(
        (Get-ObjectPropertyValue -InputObject $Exception -Name 'ResponseStatusCode'),
        (Get-ObjectPropertyValue -InputObject $response -Name 'StatusCode'),
        (Get-ObjectPropertyValue -InputObject $Exception -Name 'StatusCode')
    )) {
        if ($null -ne $candidate) {
            try { return [int]$candidate }
            catch { Write-Debug "Status code candidate was not an integer: $candidate" }
        }
    }
    return $null
}

function Get-RetryAfterDelay {
    param([Parameter(Mandatory)][object]$Exception)
    $response = Get-ObjectPropertyValue -InputObject $Exception -Name 'Response'
    $headers = Get-ObjectPropertyValue -InputObject $response -Name 'Headers'
    if ($null -eq $headers) { return $null }
    try {
        $values = $null
        if ($headers.TryGetValues('Retry-After', [ref]$values)) {
            foreach ($value in @($values)) {
                $parsed = 0
                if ([int]::TryParse([string]$value, [ref]$parsed) -and $parsed -gt 0) { return $parsed }
            }
        }
    }
    catch {
        Write-Debug "Retry-After header could not be read: $($_.Exception.Message)"
    }
    return $null
}

function Invoke-GraphRequestWithRetry {
    param(
        [Parameter(Mandatory)][ValidateSet('GET','POST','PATCH','DELETE')][string]$Method,
        [Parameter(Mandatory)][string]$Uri,
        [AllowNull()][object]$Body
    )

    $maximum = [int]$script:Configuration.Graph.MaximumRetryCount
    $initial = [int]$script:Configuration.Graph.InitialRetrySeconds

    for ($attempt = 1; $attempt -le $maximum; $attempt++) {
        try {
            $parameters = @{
                Method = $Method
                Uri = $Uri
                OutputType = 'PSObject'
            }
            if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
                $parameters.Body = ($Body | ConvertTo-Json -Depth 40)
                $parameters.ContentType = 'application/json'
            }
            return Invoke-MgGraphRequest @parameters
        }
        catch {
            $status = Get-HttpStatusCode -Exception $_.Exception
            $retryable = $status -in @(429, 500, 502, 503, 504)
            if (-not $retryable -or $attempt -eq $maximum) { throw }

            # Graph tells us how long to wait on a throttle. Prefer that over the
            # local backoff curve; fall back to it only when the header is absent.
            $delay = Get-RetryAfterDelay -Exception $_.Exception
            if ($null -eq $delay) {
                $delay = [math]::Min(60, ($initial * [math]::Pow(2, $attempt - 1)) + (Get-Random -Minimum 0 -Maximum 3))
            }
            $delay = [math]::Min(300, $delay)
            Write-WarnMessage "Graph returned HTTP $status. Retrying in $delay seconds (attempt $attempt of $maximum)."
            Start-Sleep -Seconds $delay
        }
    }

    throw "Graph request $Method $Uri exhausted $maximum attempts without a response."
}

function Get-GraphCollection {
    param([Parameter(Mandatory)][string]$Uri)
    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $response = Invoke-GraphRequestWithRetry -Method GET -Uri $next
        foreach ($item in @(Get-ObjectPropertyValue -InputObject $response -Name 'value')) {
            if ($null -ne $item) { $items.Add($item) }
        }
        $next = Get-ObjectPropertyValue -InputObject $response -Name '@odata.nextLink'
    }
    return @($items)
}

function Wait-ForGraphObject {
    param(
        [Parameter(Mandatory)][scriptblock]$Lookup,
        [Parameter(Mandatory)][string]$Description
    )
    $deadline = (Get-Date).AddSeconds([int]$script:Configuration.Graph.ConsistencyTimeoutSeconds)
    do {
        $result = & $Lookup
        if ($null -ne $result) { return $result }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
    throw "Timed out waiting for Graph consistency: $Description"
}

function Select-UniqueByDisplayName {
    param(
        # A greenfield tenant returns nothing for every lookup, which is the
        # normal first-run case and must not fail parameter binding.
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Items,
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$ObjectType
    )
    $found = @($Items | Where-Object { $_.displayName -eq $DisplayName })
    if ($found.Count -gt 1) {
        throw "Multiple $ObjectType objects use display name [$DisplayName]. Resolve duplicates before continuing."
    }
    if ($found.Count -eq 1) { return $found[0] }
    return $null
}

function Get-GroupsByDisplayName {
    param([Parameter(Mandatory)][string]$DisplayName)
    $safe = ConvertTo-ODataLiteral -Value $DisplayName
    $filter = [uri]::EscapeDataString("displayName eq '$safe'")
    return Get-GraphCollection -Uri "$script:GraphV1/groups?`$filter=$filter&`$select=id,displayName,description,groupTypes,membershipRule,membershipRuleProcessingState,mailEnabled,securityEnabled"
}

function Get-UniqueGroupByDisplayName {
    param([Parameter(Mandatory)][string]$DisplayName)
    return Select-UniqueByDisplayName -Items @(Get-GroupsByDisplayName -DisplayName $DisplayName) -DisplayName $DisplayName -ObjectType 'group'
}

function Initialize-IntuneEnrollmentServicePrincipal {
    $definition = $script:Configuration.IntuneEnrollmentServicePrincipal
    if (-not $definition.Enabled) { return }

    $safeAppId = ConvertTo-ODataLiteral -Value $definition.AppId
    $filter = [uri]::EscapeDataString("appId eq '$safeAppId'")
    $lookupUri = "$script:GraphV1/servicePrincipals?`$filter=$filter&`$select=id,appId,displayName"
    $found = @(Get-GraphCollection -Uri $lookupUri)
    if ($found.Count -gt 1) { throw "Multiple service principals use appId [$($definition.AppId)]." }
    if ($found.Count -eq 1) {
        Write-OkMessage "$($definition.DisplayName) service principal exists."
        Add-Summary -Type 'ServicePrincipal' -Name $definition.DisplayName -Action 'Check' -Status 'Exists'
        return
    }

    if (-not $script:WriteMode) {
        Write-WarnMessage "$($definition.DisplayName) service principal is missing."
        Add-Summary -Type 'ServicePrincipal' -Name $definition.DisplayName -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return
    }

    Write-InfoMessage 'Requesting Application.ReadWrite.All because the service principal is missing.'
    $null = Connect-ValidatedGraph -RequireApplicationWrite
    $null = Invoke-GraphRequestWithRetry -Method POST -Uri "$script:GraphV1/servicePrincipals" -Body @{ appId = $definition.AppId }
    $null = Wait-ForGraphObject -Description $definition.DisplayName -Lookup {
        $found = @(Get-GraphCollection -Uri $lookupUri)
        if ($found.Count -eq 1) { $found[0] } else { $null }
    }
    Write-OkMessage "$($definition.DisplayName) service principal created."
    Add-Summary -Type 'ServicePrincipal' -Name $definition.DisplayName -Action 'Create' -Status 'Created'
}

function Initialize-DynamicGroup {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $name = $Definition.DisplayName
    Write-InfoMessage "Checking dynamic group: $name"
    $group = Get-UniqueGroupByDisplayName -DisplayName $name

    if ($group) {
        $drift = @()
        if ((ConvertTo-NormalizedText $group.description) -ne (ConvertTo-NormalizedText $Definition.Description)) { $drift += 'Description differs' }
        if ($group.membershipRule -ne $Definition.MembershipRule) { $drift += 'MembershipRule differs' }
        if ($group.groupTypes -notcontains 'DynamicMembership') { $drift += 'DynamicMembership type is missing' }
        if ($group.membershipRuleProcessingState -ne 'On') { $drift += 'Membership processing is not On' }
        $status = if ($drift.Count) { 'Drift' } else { 'Exists' }
        if ($drift.Count) { Write-WarnMessage "$name drift: $($drift -join '; ')" } else { Write-OkMessage "$name exists." }
        Add-Summary -Type 'DynamicGroup' -Name $name -Action 'Check' -Status $status -Notes ($drift -join '; ')
        return $group
    }

    if (-not $script:WriteMode) {
        Write-WarnMessage "$name is missing."
        Add-Summary -Type 'DynamicGroup' -Name $name -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return $null
    }

    $mailNickname = (($name.ToLowerInvariant() -replace '[^a-z0-9]', '') + 'group')
    if ($mailNickname.Length -gt 64) { $mailNickname = $mailNickname.Substring(0, 64) }
    $body = @{
        displayName = $name
        description = $Definition.Description
        mailEnabled = $false
        mailNickname = $mailNickname
        securityEnabled = $true
        groupTypes = @('DynamicMembership')
        membershipRule = $Definition.MembershipRule
        membershipRuleProcessingState = 'On'
    }
    $created = Invoke-GraphRequestWithRetry -Method POST -Uri "$script:GraphV1/groups" -Body $body
    $group = Wait-ForGraphObject -Description $name -Lookup { Get-UniqueGroupByDisplayName -DisplayName $name }
    Write-OkMessage "$name created."
    Add-Summary -Type 'DynamicGroup' -Name $name -Action 'Create' -Status 'Created' -Notes "Id: $($created.id)"
    return $group
}

function Get-AutopilotProfile {
    return Get-GraphCollection -Uri "$script:GraphBeta/deviceManagement/windowsAutopilotDeploymentProfiles"
}

function Get-UniqueAutopilotProfileByName {
    param([Parameter(Mandatory)][string]$DisplayName)
    return Select-UniqueByDisplayName -Items @(Get-AutopilotProfile) -DisplayName $DisplayName -ObjectType 'Autopilot profile'
}

function Get-AutopilotProfileBody {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $a = $script:Configuration.Autopilot
    $body = @{
        '@odata.type' = '#microsoft.graph.azureADWindowsAutopilotDeploymentProfile'
        displayName = $Definition.DisplayName
        description = $Definition.Description
        locale = $a.Locale
        hardwareHashExtractionEnabled = [bool]$a.ConvertTargetedDevices
        deviceType = 'windowsPc'
        preprovisioningAllowed = [bool]$Definition.PreprovisioningAllowed
        roleScopeTagIds = @($a.RoleScopeTagIds)
        outOfBoxExperienceSetting = @{
            '@odata.type' = '#microsoft.graph.outOfBoxExperienceSetting'
            privacySettingsHidden = [bool]$a.HidePrivacySettings
            eulaHidden = [bool]$a.HideEula
            userType = $a.UserType
            deviceUsageType = $a.DeviceUsageType
            keyboardSelectionPageSkipped = [bool]$a.SkipKeyboardSelectionPage
            escapeLinkHidden = [bool]$a.HideEscapeLink
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($Definition.DeviceNameTemplate)) {
        $body.deviceNameTemplate = $Definition.DeviceNameTemplate
    }
    return $body
}

function Initialize-AutopilotProfile {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $name = $Definition.DisplayName
    Write-InfoMessage "Checking Autopilot profile: $name"
    $apProfile = Get-UniqueAutopilotProfileByName -DisplayName $name
    if ($apProfile) {
        $expected = Get-AutopilotProfileBody -Definition $Definition
        $drift = @()
        if ((ConvertTo-NormalizedText $apProfile.description) -ne (ConvertTo-NormalizedText $Definition.Description)) { $drift += 'Description differs' }
        if ((ConvertTo-NormalizedText $apProfile.deviceNameTemplate) -ne (ConvertTo-NormalizedText $Definition.DeviceNameTemplate)) { $drift += 'DeviceNameTemplate differs' }
        if ($apProfile.locale -ne $expected.locale) { $drift += 'Locale differs' }
        if ([bool]$apProfile.hardwareHashExtractionEnabled -ne [bool]$expected.hardwareHashExtractionEnabled) { $drift += 'HardwareHashExtractionEnabled differs' }
        if ([bool]$apProfile.preprovisioningAllowed -ne [bool]$expected.preprovisioningAllowed) { $drift += 'PreprovisioningAllowed differs' }
        foreach ($property in @('privacySettingsHidden','eulaHidden','userType','deviceUsageType','keyboardSelectionPageSkipped','escapeLinkHidden')) {
            if ($apProfile.outOfBoxExperienceSetting.$property -ne $expected.outOfBoxExperienceSetting.$property) { $drift += "OOBE $property differs" }
        }
        $status = if ($drift.Count) { 'Drift' } else { 'Exists' }
        if ($drift.Count) { Write-WarnMessage "$name drift: $($drift -join '; ')" } else { Write-OkMessage "$name exists." }
        Add-Summary -Type 'AutopilotProfile' -Name $name -Action 'Check' -Status $status -Notes ($drift -join '; ')
        return $apProfile
    }

    if (-not $script:WriteMode) {
        Write-WarnMessage "$name is missing."
        Add-Summary -Type 'AutopilotProfile' -Name $name -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return $null
    }

    $body = Get-AutopilotProfileBody -Definition $Definition
    $created = Invoke-GraphRequestWithRetry -Method POST -Uri "$script:GraphBeta/deviceManagement/windowsAutopilotDeploymentProfiles" -Body $body
    $apProfile = Wait-ForGraphObject -Description $name -Lookup { Get-UniqueAutopilotProfileByName -DisplayName $name }
    Write-OkMessage "$name created."
    Add-Summary -Type 'AutopilotProfile' -Name $name -Action 'Create' -Status 'Created' -Notes "Id: $($created.id)"
    return $apProfile
}

function Initialize-AutopilotProfileAssignment {
    param([Parameter(Mandatory)][object]$ApProfile, [Parameter(Mandatory)][string]$GroupName)
    $group = Get-UniqueGroupByDisplayName -DisplayName $GroupName
    $label = "$($ApProfile.displayName) -> $GroupName"
    if (-not $group) {
        Add-Summary -Type 'AutopilotAssignment' -Name $label -Action 'Check' -Status 'Missing' -Notes 'Target group does not exist'
        if ($script:WriteMode) { throw "Target group [$GroupName] does not exist." }
        return
    }

    $uri = "$script:GraphBeta/deviceManagement/windowsAutopilotDeploymentProfiles/$($ApProfile.id)/assignments"
    $assignments = @(Get-GraphCollection -Uri $uri)
    $match = @($assignments | Where-Object { $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and $_.target.groupId -eq $group.id })
    if ($match.Count -gt 1) { throw "Duplicate Autopilot assignments found for [$label]." }
    if ($match.Count -eq 1) {
        $extra = @($assignments | Where-Object { $_.target.groupId -ne $group.id })
        $status = if ($extra.Count) { 'Drift' } else { 'Exists' }
        $notes = if ($extra.Count) { "Preserved extra assignments: $($extra.Count)" } else { '' }
        Add-Summary -Type 'AutopilotAssignment' -Name $label -Action 'Check' -Status $status -Notes $notes
        return
    }

    if (-not $script:WriteMode) {
        Add-Summary -Type 'AutopilotAssignment' -Name $label -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return
    }
    $body = @{
        '@odata.type' = '#microsoft.graph.windowsAutopilotDeploymentProfileAssignment'
        target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $group.id }
    }
    $null = Invoke-GraphRequestWithRetry -Method POST -Uri $uri -Body $body
    $null = Wait-ForGraphObject -Description $label -Lookup {
        @(Get-GraphCollection -Uri $uri) | Where-Object { $_.target.groupId -eq $group.id } | Select-Object -First 1
    }
    Add-Summary -Type 'AutopilotAssignment' -Name $label -Action 'Create' -Status 'Created'
}

function Get-AssignmentFilter {
    return Get-GraphCollection -Uri "$script:GraphBeta/deviceManagement/assignmentFilters"
}

function Get-UniqueAssignmentFilterByName {
    param([Parameter(Mandatory)][string]$DisplayName)
    return Select-UniqueByDisplayName -Items @(Get-AssignmentFilter) -DisplayName $DisplayName -ObjectType 'assignment filter'
}

function Initialize-DeviceFilter {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $name = $Definition.DisplayName
    Write-InfoMessage "Checking assignment filter: $name"
    $filter = Get-UniqueAssignmentFilterByName -DisplayName $name
    if ($filter) {
        $drift = @()
        if ((ConvertTo-NormalizedText $filter.description) -ne (ConvertTo-NormalizedText $Definition.Description)) { $drift += 'Description differs' }
        if ($filter.platform -ne $Definition.Platform) { $drift += 'Platform differs' }
        if ($filter.rule -ne $Definition.Rule) { $drift += 'Rule differs' }
        if ($filter.assignmentFilterManagementType -ne 'devices') { $drift += 'Management type differs' }
        $status = if ($drift.Count) { 'Drift' } else { 'Exists' }
        if ($drift.Count) { Write-WarnMessage "$name drift: $($drift -join '; ')" } else { Write-OkMessage "$name exists." }
        Add-Summary -Type 'DeviceFilter' -Name $name -Action 'Check' -Status $status -Notes ($drift -join '; ')
        return $filter
    }

    if (-not $script:WriteMode) {
        Add-Summary -Type 'DeviceFilter' -Name $name -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return $null
    }
    $body = @{
        '@odata.type' = '#microsoft.graph.deviceAndAppManagementAssignmentFilter'
        displayName = $name
        description = $Definition.Description
        platform = $Definition.Platform
        rule = $Definition.Rule
        assignmentFilterManagementType = 'devices'
        roleScopeTags = @('0')
    }
    $created = Invoke-GraphRequestWithRetry -Method POST -Uri "$script:GraphBeta/deviceManagement/assignmentFilters" -Body $body
    $filter = Wait-ForGraphObject -Description $name -Lookup { Get-UniqueAssignmentFilterByName -DisplayName $name }
    Add-Summary -Type 'DeviceFilter' -Name $name -Action 'Create' -Status 'Created' -Notes "Id: $($created.id)"
    return $filter
}

function Resolve-BlockingApplication {
    $names = @($script:Configuration.Esp.BlockingAppDisplayNames)
    if ($names.Count -eq 0) {
        $script:ResolvedBlockingAppIds = @()
        Write-OkMessage 'No tenant-specific ESP blocking applications are configured.'
        return
    }

    $apps = @(Get-GraphCollection -Uri "$script:GraphBeta/deviceAppManagement/mobileApps?`$select=id,displayName")
    $ids = @()
    foreach ($name in $names) {
        $found = @($apps | Where-Object displayName -eq $name)
        if ($found.Count -ne 1) {
            throw "ESP blocking application [$name] matched $($found.Count) Intune applications; exactly one is required."
        }
        $ids += $found[0].id
    }
    $script:ResolvedBlockingAppIds = $ids
    Write-OkMessage "Resolved $($ids.Count) ESP blocking application(s)."
}

# Enrollment Status Page settings live on the beta resource. The v1.0
# windows10EnrollmentCompletionPageConfiguration exposes only the inherited
# deviceEnrollmentConfiguration properties plus allowNonBlockingAppInstallation,
# so a v1.0 write silently discards the fail-open setting, the timeout, the
# custom message and the selected app list. Read and write ESP through beta.
function Get-EspProfile {
    return Get-GraphCollection -Uri "$script:GraphBeta/deviceManagement/deviceEnrollmentConfigurations"
}

function Get-UniqueEspByName {
    param([Parameter(Mandatory)][string]$DisplayName)
    $items = @(Get-EspProfile | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration' })
    return Select-UniqueByDisplayName -Items $items -DisplayName $DisplayName -ObjectType 'ESP profile'
}

function Get-EspBody {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $e = $script:Configuration.Esp
    return @{
        '@odata.type' = '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration'
        displayName = $Definition.DisplayName
        description = $Definition.Description
        priority = [int]$Definition.Priority
        roleScopeTagIds = @($e.RoleScopeTagIds)
        showInstallationProgress = [bool]$e.ShowInstallationProgress
        blockDeviceSetupRetryByUser = [bool]$e.BlockDeviceSetupRetryByUser
        allowDeviceResetOnInstallFailure = [bool]$e.AllowDeviceResetOnInstallFailure
        allowLogCollectionOnInstallFailure = [bool]$e.AllowLogCollectionOnInstallFailure
        customErrorMessage = $e.CustomErrorMessage
        installProgressTimeoutInMinutes = [int]$e.InstallProgressTimeoutInMinutes
        allowDeviceUseOnInstallFailure = [bool]$e.AllowDeviceUseOnInstallFailure
        selectedMobileAppIds = @($script:ResolvedBlockingAppIds)
        allowNonBlockingAppInstallation = ($script:ResolvedBlockingAppIds.Count -gt 0)
        installQualityUpdates = [bool]$e.InstallQualityUpdates
        trackInstallProgressForAutopilotOnly = [bool]$e.TrackInstallProgressForAutopilotOnly
        disableUserStatusTrackingAfterFirstUser = [bool]$e.DisableUserStatusTrackingAfterFirstUser
    }
}

function Initialize-EspProfile {
    param([Parameter(Mandatory)][hashtable]$Definition)
    $name = $Definition.DisplayName
    Write-InfoMessage "Checking ESP profile: $name"
    $esp = Get-UniqueEspByName -DisplayName $name
    $expected = Get-EspBody -Definition $Definition
    if ($esp) {
        $drift = @()
        foreach ($property in @(
            'description','priority','showInstallationProgress','blockDeviceSetupRetryByUser',
            'allowDeviceResetOnInstallFailure','allowLogCollectionOnInstallFailure','customErrorMessage',
            'installProgressTimeoutInMinutes','allowDeviceUseOnInstallFailure','allowNonBlockingAppInstallation',
            'installQualityUpdates','trackInstallProgressForAutopilotOnly','disableUserStatusTrackingAfterFirstUser'
        )) {
            $actualValue = Get-ObjectPropertyValue -InputObject $esp -Name $property
            $expectedValue = Get-ObjectPropertyValue -InputObject $expected -Name $property
            if ((ConvertTo-NormalizedText $actualValue) -ne (ConvertTo-NormalizedText $expectedValue)) { $drift += "$property differs" }
        }
        $actualAppIds = @(Get-ObjectPropertyValue -InputObject $esp -Name 'selectedMobileAppIds')
        if (-not (Test-EquivalentCollection -Actual $actualAppIds -Expected @($expected.selectedMobileAppIds))) {
            $drift += 'selectedMobileAppIds differs'
        }
        $status = if ($drift.Count) { 'Drift' } else { 'Exists' }
        if ($drift.Count) { Write-WarnMessage "$name drift: $($drift -join '; ')" } else { Write-OkMessage "$name exists." }
        Add-Summary -Type 'ESPProfile' -Name $name -Action 'Check' -Status $status -Notes ($drift -join '; ')
        return $esp
    }

    # Priority orders every ESP in the tenant, so a value already held by an
    # unrelated profile produces ambiguous evaluation order rather than an error.
    $collision = @(Get-EspProfile |
        Where-Object { $_.'@odata.type' -eq '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration' } |
        Where-Object { [int](Get-ObjectPropertyValue -InputObject $_ -Name 'priority') -eq [int]$Definition.Priority })
    if ($collision.Count -gt 0) {
        $holder = ($collision | ForEach-Object { $_.displayName }) -join ', '
        $note = "Priority $($Definition.Priority) is already held by: $holder"
        Write-WarnMessage "$name would collide on priority. $note"
        Add-Summary -Type 'ESPProfile' -Name $name -Action 'Create' -Status 'Blocked' -Notes $note
        if ($script:WriteMode) {
            throw "ESP priority $($Definition.Priority) is already used by [$holder]. Choose a free priority in IntuneTenantBootstrap.psd1 before applying."
        }
        return $null
    }

    if (-not $script:WriteMode) {
        Add-Summary -Type 'ESPProfile' -Name $name -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return $null
    }
    $created = Invoke-GraphRequestWithRetry -Method POST -Uri "$script:GraphBeta/deviceManagement/deviceEnrollmentConfigurations" -Body $expected
    $esp = Wait-ForGraphObject -Description $name -Lookup { Get-UniqueEspByName -DisplayName $name }
    Add-Summary -Type 'ESPProfile' -Name $name -Action 'Create' -Status 'Created' -Notes "Id: $($created.id)"
    return $esp
}

function Initialize-EspAssignment {
    param([Parameter(Mandatory)][object]$Esp, [Parameter(Mandatory)][string]$GroupName)
    $group = Get-UniqueGroupByDisplayName -DisplayName $GroupName
    $label = "$($Esp.displayName) -> $GroupName"
    if (-not $group) {
        Add-Summary -Type 'ESPAssignment' -Name $label -Action 'Check' -Status 'Missing' -Notes 'Target group does not exist'
        if ($script:WriteMode) { throw "Target group [$GroupName] does not exist." }
        return
    }

    $uri = "$script:GraphBeta/deviceManagement/deviceEnrollmentConfigurations/$($Esp.id)/assignments"
    $assignments = @(Get-GraphCollection -Uri $uri)
    $match = @($assignments | Where-Object { $_.target.'@odata.type' -eq '#microsoft.graph.groupAssignmentTarget' -and $_.target.groupId -eq $group.id })
    if ($match.Count -gt 1) { throw "Duplicate ESP assignments found for [$label]." }
    if ($match.Count -eq 1) {
        $extra = @($assignments | Where-Object { $_.target.groupId -ne $group.id })
        $status = if ($extra.Count) { 'Drift' } else { 'Exists' }
        $notes = if ($extra.Count) { "Preserved extra assignments: $($extra.Count)" } else { '' }
        Add-Summary -Type 'ESPAssignment' -Name $label -Action 'Check' -Status $status -Notes $notes
        return
    }

    if (-not $script:WriteMode) {
        Add-Summary -Type 'ESPAssignment' -Name $label -Action 'Create' -Status 'Missing' -Notes 'Report-only mode'
        return
    }

    # Create one assignment through the assignments collection. This is additive
    # and preserves every unrelated assignment already present on the ESP.
    $body = @{
        '@odata.type' = '#microsoft.graph.enrollmentConfigurationAssignment'
        target = @{
            '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
            groupId = $group.id
        }
    }
    $null = Invoke-GraphRequestWithRetry -Method POST -Uri $uri -Body $body
    $null = Wait-ForGraphObject -Description $label -Lookup {
        @(Get-GraphCollection -Uri $uri) | Where-Object { $_.target.groupId -eq $group.id } | Select-Object -First 1
    }
    Add-Summary -Type 'ESPAssignment' -Name $label -Action 'Create' -Status 'Created'
}

function Invoke-TenantBootstrap {
    param([Parameter(Mandatory)][scriptblock]$ConfirmApply)

    Test-PowerShellVersion
    Import-AndValidateConfiguration
    Initialize-GraphAuthenticationModule
    Start-PackageLogging

    $null = Connect-ValidatedGraph
    Resolve-BlockingApplication

    if ($script:WriteMode) {
        $script:WriteMode = [bool](& $ConfirmApply)
        if (-not $script:WriteMode) {
            Write-WarnMessage 'Apply was not confirmed. Continuing as report-only.'
        }
    }

    Write-Host ''
    Write-Host '=== 1. Microsoft Intune Enrollment service principal ===' -ForegroundColor Magenta
    Initialize-IntuneEnrollmentServicePrincipal

    Write-Host ''
    Write-Host '=== 2. Dynamic Microsoft Entra device groups ===' -ForegroundColor Magenta
    $groups = @{}
    foreach ($definition in $script:DynamicGroupDefinitions) {
        $group = Initialize-DynamicGroup -Definition $definition
        if ($group) { $groups[$definition.DisplayName] = $group }
    }

    Write-Host ''
    Write-Host '=== 3. Windows Autopilot deployment profiles ===' -ForegroundColor Magenta
    $apProfiles = @{}
    foreach ($definition in $script:AutopilotProfileDefinitions) {
        $apProfile = Initialize-AutopilotProfile -Definition $definition
        if ($apProfile) { $apProfiles[$definition.DisplayName] = $apProfile }
    }

    Write-Host ''
    Write-Host '=== 4. Autopilot profile assignments ===' -ForegroundColor Magenta
    foreach ($definition in $script:AutopilotProfileDefinitions) {
        $apProfile = $apProfiles[$definition.DisplayName]
        if (-not $apProfile) { $apProfile = Get-UniqueAutopilotProfileByName -DisplayName $definition.DisplayName }
        if ($apProfile) { Initialize-AutopilotProfileAssignment -ApProfile $apProfile -GroupName $definition.AssignedGroupName }
    }

    Write-Host ''
    Write-Host '=== 5. Intune assignment filters ===' -ForegroundColor Magenta
    foreach ($definition in $script:DeviceFilterDefinitions) {
        $null = Initialize-DeviceFilter -Definition $definition
    }

    Write-Host ''
    Write-Host '=== 6. Enrollment Status Page profiles ===' -ForegroundColor Magenta
    $espProfiles = @{}
    foreach ($definition in $script:EspDefinitions) {
        $esp = Initialize-EspProfile -Definition $definition
        if ($esp) { $espProfiles[$definition.DisplayName] = $esp }
    }

    Write-Host ''
    Write-Host '=== 7. Enrollment Status Page assignments ===' -ForegroundColor Magenta
    foreach ($definition in $script:EspDefinitions) {
        $esp = $espProfiles[$definition.DisplayName]
        if (-not $esp) { $esp = Get-UniqueEspByName -DisplayName $definition.DisplayName }
        if ($esp) { Initialize-EspAssignment -Esp $esp -GroupName $definition.AssignedGroupName }
    }

    Write-Host ''
    Write-Host '=== Summary ===' -ForegroundColor Magenta
    $script:Summary | Sort-Object Type, Name | Format-Table -AutoSize -Wrap
    if ($script:WriteMode) { Write-OkMessage 'Apply run completed.' }
    else { Write-OkMessage 'Report-only run completed.' }
}

try {
    Invoke-TenantBootstrap -ConfirmApply {
        $PSCmdlet.ShouldProcess(
            "Microsoft tenant $TenantId",
            'Create missing Intune, Entra, Autopilot, filter, and ESP objects'
        )
    }
}
catch {
    Write-FailMessage $_.Exception.Message
    throw
}
finally {
    try { Export-PackageSummary } catch { Write-WarnMessage "Summary export failed: $($_.Exception.Message)" }
    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }
    if ($script:TranscriptStarted) { Stop-Transcript | Out-Null }
}
