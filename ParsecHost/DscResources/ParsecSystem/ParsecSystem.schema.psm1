Configuration ParsecSystem
{
	Param()

    Import-DscResource -ModuleName 'PSDscResources'

    # Required features built-in to Windows
    WindowsFeatureSet "Install-WindowsFeatures"
    {
        Ensure = 'Present'
        Name = 'NET-Framework-Core','NET-Framework-45-Core','Direct-Play'
    }

    # Disable Internet Explorer Enhanced Security Configuration
    Registry "Disable-IE-ESC-Admin"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
        ValueName = 'IsInstalled'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }
    Registry "Disable-IE-ESC-User"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
        ValueName = 'IsInstalled'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
    }

    # # Disable Windows Automatic Updates
    Registry "Disable-AutomaticUpdates"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
        ValueName = 'NoAutoUpdate'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Configure NTP
    Registry "Enable-NTP"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters'
        ValueName = 'Type'
        ValueData = 'NTP'
        ValueType = 'String'
        Force = $true
    }
    Registry "Set-TimeZoneUpdate-Service-ManualTrigger"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate'
        ValueName = 'Start'
        ValueData = 3
        ValueType = 'Dword'
        Force = $true
    }
    
    # # Disable New Network UI
    Registry "Disable-NewNetwork-GUI"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff'
        ValueName = ''
        Force = $true
    }
    
    # # Disable Server Manager at login
    Registry "Disable-ServerManager-Startup"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Server\ServerManager'
        ValueName = 'DoNotOpenAtLogon'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Disable lockscreen
    Registry "Disable-Lockscreen"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
        ValueName = 'DisableLockWorkstation'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }

    # # Disable recently installed items in start menu
    Registry "Disable-StartMenu-RecentlyInstalled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
        ValueName = 'HideRecentlyAddedApps'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
    }
}
