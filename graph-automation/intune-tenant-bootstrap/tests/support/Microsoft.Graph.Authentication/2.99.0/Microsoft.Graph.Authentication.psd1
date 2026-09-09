@{
    RootModule        = 'Microsoft.Graph.Authentication.psm1'
    ModuleVersion     = '2.99.0'
    GUID              = 'b1e2c3d4-0000-4000-8000-abcdefabcdef'
    Author            = 'Offline test double'
    Description       = 'Offline stand-in for Microsoft.Graph.Authentication. Never contacts Microsoft Graph.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Connect-MgGraph', 'Disconnect-MgGraph', 'Get-MgContext', 'Invoke-MgGraphRequest')
}
