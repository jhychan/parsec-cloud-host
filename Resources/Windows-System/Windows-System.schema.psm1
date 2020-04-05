Configuration Windows-System
{
	Param()

    Import-DscResource -ModuleName 'PSDscResources'

    Node $AllNodes
    {
        # Required features built-in to Windows
        WindowsOptionalFeature "Install-.NET-Framework-3.5"
        {
            Ensure = 'Present'
            Name = 'Net-Framework-Core'
        }

        WindowsOptionalFeature "Install-DirectPlay"
        {
            Ensure = 'Present'
            Name = 'Direct-Play'
        }

        # Disable Internet Explorer Enhanced Security Configuration
        Registry "Disable-IE-ESC-Admin"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
            ValueName = 'IsInstalled'
            ValueData = 0
            ValueType = 'Dword'
        }

        Registry "Disable-IE-ESC-User"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
            ValueName = 'IsInstalled'
            ValueData = 0
            ValueType = 'Dword'
        }

        # Disable Windows Update Services
        Registry "Disable-Windows-Update-AutomaticUpdates"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'AUOptions'
            ValueData = 1
            ValueType = 'Dword'
        }

        Registry "Disable-Windows-Update-UseWSUS"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
            ValueName = 'UseWUServer'
            ValueData = 1
            ValueType = 'Dword'
        }

        Registry "Disable-Windows-Update-InternetLocations"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'DoNotConnectToWindowsUpdateInternetLocations'
            ValueData = 1
            ValueType = 'Dword'
        }

        Registry "Disable-Windows-Update-UpdateServiceURL"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'UpdateServiceURLAlternative'
            ValueData = 'http://localhost'
            ValueType = 'String'
        }

        Registry "Disable-Windows-Update-WSUS-URL"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'WUServer'
            ValueData = 'http://localhost'
            ValueType = 'String'
        }

        Registry "Disable-Windows-Update-WSUS-Status-URL"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
            ValueName = 'WUSatusServer'
            ValueData = 'http://localhost'
            ValueType = 'String'
        }

        # Configure NTP
        Registry "Enable-NTP"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
            ValueName = 'Type'
            ValueData = 'NTP'
            ValueType = 'String'
        }

        Registry "Set-TimeZoneUpdate-Service-ManualTrigger"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tzautoupdate'
            ValueName = 'Start'
            ValueData = 3
            ValueType = 'Dword'
        }
        
        # Disable New Network UI
        Registry "Disable-NewNetwork-GUI"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff'
        }

        # Disable Server Manager at login
        Registry "Disable-ServerManager-Startup"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Server\ServerManager'
            ValueName = 'DoNotOpenAtLogon'
            ValueData = 1
            ValueType = 'Dword'
        }

        # Disable lockscreen
        Registry "Disable-Lockscreen"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'DisableLockWorkstation'
            ValueData = 1
            ValueType = 'Dword'
        }

        # Disable recently installed items in start menu
        Registry "Disable-StartMenu-RecentlyInstalled"
        {
            Ensure = 'Present'
            Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Explorer'
            ValueName = 'HideRecentlyAddedApps'
            ValueData = 1
            ValueType = 'Dword'
        }
    }
}
