@{
    SchemaVersion = '1.1'

    # Canonical names. Profile names are used to generate the assignment-filter
    # rules, so the filter rules cannot drift from the profile names.
    Naming = @{
        PilotTag                  = 'EntraID-PilotDevice'
        ProductionTag             = 'EntraID-ProdDevice'

        PilotTagGroup             = 'Autopilot Tag - EntraID-PilotDevice'
        ProductionTagGroup        = 'Autopilot Tag - EntraID-ProdDevice'
        AllAutopilotGroup         = 'Autopilot Devices - All Corporate Autopilot Devices'
        ExistingDeviceIntakeGroup = 'All Corporate Windows Devices Not in Autopilot'

        PilotProfile               = 'Deployment EntraID Pilot Devices'
        ProductionProfile          = 'Deployment EntraID Prod Devices'
        ExistingDeviceProfile      = 'Onboard Existing Devices to Autopilot'

        PilotFilter                = 'Autopilot Filter - EntraID-PilotDevice'
        ProductionFilter           = 'Autopilot Filter - EntraID-ProdDevice'
        CombinedFilter             = 'Autopilot Filter - EntraID-PilotAndProdDevices'

        PilotEsp                   = 'Windows 11 EntraID Pilot Devices'
        ProductionEsp              = 'Windows 11 EntraID Prod Devices'
    }

    ExistingDeviceIntake = @{
        Enabled                  = $true
        CompanyOwnedDevicesOnly = $true
    }

    Autopilot = @{
        Locale                    = 'os-default'
        DeviceNameTemplate        = '%SERIAL%'
        UserType                  = 'standard'
        DeviceUsageType           = 'singleUser'
        HidePrivacySettings       = $true
        HideEula                  = $true
        SkipKeyboardSelectionPage = $true
        HideEscapeLink            = $true
        EnablePreprovisioning      = $true
        ConvertTargetedDevices     = $true
        RoleScopeTagIds            = @('0')
    }

    Esp = @{
        ShowInstallationProgress                 = $true
        BlockDeviceSetupRetryByUser              = $false
        AllowDeviceResetOnInstallFailure         = $true
        AllowLogCollectionOnInstallFailure       = $true
        AllowDeviceUseOnInstallFailure           = $true
        CustomErrorMessage                       = 'Setup could not be completed. Please try again or contact your support person for help.'
        InstallProgressTimeoutInMinutes          = 60
        InstallQualityUpdates                    = $true
        TrackInstallProgressForAutopilotOnly     = $true
        DisableUserStatusTrackingAfterFirstUser  = $true
        RoleScopeTagIds                          = @('0')

        # Enrollment Status Page priority orders every ESP in the tenant, not
        # just the two this package owns. A tenant that already runs custom ESPs
        # needs free values here; the package refuses to create over a
        # priority another profile already holds.
        PilotPriority                            = 1
        ProductionPriority                       = 2

        # Empty means the package has no tenant-specific selected blocking-app
        # list. Required applications are assigned separately in Intune.
        BlockingAppDisplayNames                  = @()
    }

    IntuneEnrollmentServicePrincipal = @{
        Enabled     = $true
        AppId       = 'd4ebce55-015a-49b5-a083-c84d1797ae8c'
        DisplayName = 'Microsoft Intune Enrollment'
    }

    Graph = @{
        MinimumModuleVersion = '2.35.1'
        MaximumRetryCount    = 6
        InitialRetrySeconds  = 2
        ConsistencyTimeoutSeconds = 90
    }
}
