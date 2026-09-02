# Offline stand-in for Microsoft.Graph.Authentication.
#
# The real module is never installed by the offline tests and no network call is
# made. The double keeps a small in-memory tenant so an apply run can be
# exercised end to end: a POST to a collection adds an object to that
# collection, and a later GET returns it, which is what the package's
# consistency polling waits for.
#
# $global:OfflineGraphSeed  pre-existing tenant state, as @{ Path = '...'; Value = @(...) }
# $global:OfflineGraphLog   every request, so a test can assert endpoint versions
# $global:OfflineGraphStore the live collection store

function Connect-MgGraph {
    [CmdletBinding()]
    param(
        [string]$TenantId,
        [string[]]$Scopes,
        [string]$ContextScope,
        [switch]$NoWelcome,
        [switch]$UseDeviceAuthentication
    )
    $global:OfflineGraphTenantId = $TenantId
    $global:OfflineGraphScopes = @($Scopes)
}

function Disconnect-MgGraph { [CmdletBinding()] param() }

function Get-MgContext {
    [CmdletBinding()] param()
    return [pscustomobject]@{
        TenantId = $global:OfflineGraphTenantId
        Account  = 'offline.operator@example.invalid'
        Scopes   = @($global:OfflineGraphScopes)
    }
}

function Get-OfflineCollectionKey {
    param([string]$Uri)
    $path = ($Uri -split '\?')[0]
    # Collapse the API version so a v1.0 and a beta call to the same collection
    # share state. A test that cares about the version reads the request log.
    return ($path -replace 'https://graph\.microsoft\.com/(v1\.0|beta)/', '')
}

function Invoke-MgGraphRequest {
    [CmdletBinding()]
    param(
        [string]$Method,
        [string]$Uri,
        [object]$Body,
        [string]$ContentType,
        [string]$OutputType
    )

    if (-not $global:OfflineGraphLog) { $global:OfflineGraphLog = [System.Collections.Generic.List[object]]::new() }
    $global:OfflineGraphLog.Add([pscustomobject]@{ Method = $Method; Uri = $Uri; Body = $Body }) | Out-Null

    $key = Get-OfflineCollectionKey -Uri $Uri
    if (-not $global:OfflineGraphStore.ContainsKey($key)) { $global:OfflineGraphStore[$key] = @() }

    if ($Method -eq 'POST') {
        $object = [ordered]@{ id = 'offline-' + ([string]($global:OfflineGraphLog.Count)) }
        $payload = if ($Body -is [string]) { $Body | ConvertFrom-Json } else { $Body }
        foreach ($property in @($payload.PSObject.Properties)) { $object[$property.Name] = $property.Value }
        $created = [pscustomobject]$object
        $global:OfflineGraphStore[$key] = @($global:OfflineGraphStore[$key]) + $created
        return $created
    }

    if ($Method -ne 'GET') { return [pscustomobject]@{ id = 'offline-noop' } }

    $items = @($global:OfflineGraphStore[$key])

    # Honour only the filter shapes the package actually sends.
    if ($Uri -match "displayName\+?eq\+?'([^']*)'" -or $Uri -match "displayName%20eq%20'([^']*)'") {
        $wanted = [uri]::UnescapeDataString($Matches[1])
        $items = @($items | Where-Object { $_.displayName -eq $wanted })
    }
    elseif ($Uri -match "appId\+?eq\+?'([^']*)'" -or $Uri -match "appId%20eq%20'([^']*)'") {
        $wanted = [uri]::UnescapeDataString($Matches[1])
        $items = @($items | Where-Object { $_.appId -eq $wanted })
    }

    return [pscustomobject]@{ value = $items }
}

Export-ModuleMember -Function Connect-MgGraph, Disconnect-MgGraph, Get-MgContext, Invoke-MgGraphRequest
