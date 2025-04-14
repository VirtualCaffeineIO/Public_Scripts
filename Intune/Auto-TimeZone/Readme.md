

For anyone else looking into this for automatic Time Zone updates, I added:

MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy

To the policy, which was successful.

For Intune device location, it seemed to work without any policy additions. I don't even see any Intune related item show up in the Settings -> Privacy & security -> Location -> Recent activity section.



##################


If you're like me and you truly just want the Automatic Time Zone to be set, but you want everything else to be up to the user with the default settings to be "Off" due to Europe or another regions concern of location services here's what you do: 


###################


 Intune > Devices > Configuration > New Policy > Windows 10 & Later > Settings Catalog

Select the following settings:

    PRIVACY

        Let Apps Access Location:

            Force Deny

        Let Apps Access Location Force Allow These Apps:

            windows.immersivecontrolpanel_cw5n1h2txyewy

        Let Apps Access Location User In Control Of These Apps (These are just standard ones, use Get-AppxPackage to find any installed in your environment):

            Microsoft.WindowsCamera_8wekyb3d8bbwe

            microsoft.windowscommunicationsapps_8wekyb3d8bbwe

            Microsoft.WindowsMaps_8wekyb3d8bbwe

            MSTeams_8wekyb3d8bbwe

            MicrosoftTeams_8wekyb3d8bbwe

            Microsoft.BingNews_8wekyb3d8bbwe

            Microsoft.OutlookForWindows_8wekyb3d8bbwe

            Microsoft.BingWeather_8wekyb3d8bbwe

            Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy

            MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy

            Microsoft.Win32WebViewHost_cw5n1h2txyewy

    SYSTEM

        Allow Location:

            Force Location Off. All Location Privacy settings are toggled off and grayed out. Users cannot change the settings, and no apps are allowed access to the Location service, including Cortana and Search.





Now finally, you'll need to set the Automatic Time Zone selector to be on. This can be done in any of your favorite ways, but I want it forced on my user and only controlled by an Admin (the few support requests when it's broken is far better than the questions we get all the time from traveling users).
Here are some basic script commands you can use, but best to wrap these up with logging... or don't :)

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate\" -Name "Start" -Type "DWORD" -Value "3" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "String" -Value "Allow" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type "DWord" -Value 1 -Force
Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
W32tm /resync /force

VOILA! You now have every location service soft disabled, except for the Settings app which is always on. 
In turn, your users have the control they need if they'd rather have Weather or News location on.
Deploying this to existing users also keeps their current location service selection as an added bonus, but only as long as the app is in that list of User Controlled apps.
Add or remove to that as necessary as all new applications will obviously be disabled without user control. Good luck!
