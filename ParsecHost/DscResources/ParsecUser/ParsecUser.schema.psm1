Configuration ParsecUser
{
	Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName 'PSDscResources'

    # Local user account running parsec
    User "User-Parsec"
    {
        Ensure = 'Present'
        UserName = $Credential.UserName
        Password = $Credential
    }
    Group "Administrator-Parsec"
    {
        Ensure= 'Present'
        GroupName='Administrators'
        MembersToInclude = $Credential.UserName
        DependsOn = '[User]User-Parsec'
    }

    # Disable IE Proxy
    Registry "Disable-IE-Proxy"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        ValueName = 'ProxyEnable'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Force close processes on shutdown
    Registry "Shutdown-Force-Kill-Processes"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Desktop'
        ValueName = 'AutoEndTasks'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    
    # Disable mouse acceleration
    Registry "Disable-Mouse-Acceleration"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Mouse'
        ValueName = 'MouseSpeed'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Sensible explorer settings
    Registry "Disable-Explorer-RecentFiles"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        ValueName = 'ShowRecent'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Disable-Explorer-FrequentFolders"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        ValueName = 'ShowFrequent'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Disable-Explorer-LaunchToQuickAccess"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'LaunchTo'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Enable-Explorer-ShowHidden"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'Hidden'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Disable-Explorer-HideFileExtensions"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'HideFileExt'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Disable-Explorer-TaskbarTaskView"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'ShowTaskViewButton'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Disable-Explorer-TaskbarSearch"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'SearchboxTaskbarMode'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Clear last logged on user
    Registry "Clear-LastLoggedOnDisplayName"
    {
        Ensure = 'Absent'
        Key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
        ValueName = 'LastLoggedOnDisplayName'
    }
    Registry "Clear-LastLoggedOnSAMUser"
    {
        Ensure = 'Absent'
        Key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
        ValueName = 'LastLoggedOnSAMUser'
    }
    Registry "Clear-LastLoggedOnUser"
    {
        Ensure = 'Absent'
        Key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
        ValueName = 'LastLoggedOnUser'
    }
    Registry "Clear-LastLoggedOnUserSID"
    {
        Ensure = 'Absent'
        Key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI'
        ValueName = 'LastLoggedOnUserSID'
    }
    Registry "Clear-AutoLogonCount"
    {
        Ensure = 'Absent'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'AutoLogonCount'
    }

    # Configure autologon
    Registry "Enable-AutoLogon"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'AutoAdminLogon'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]User-Parsec'
    }
    Registry "Enable-AutoLogon-Domain"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultDomainName'
        ValueData = '.'
        ValueType = 'String'
        Force = $true
        DependsOn = '[User]User-Parsec'
    }
    Registry "Enable-AutoLogon-Username"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultUserName'
        ValueData = $Credential.UserName
        ValueType = 'String'
        Force = $true
        DependsOn = '[User]User-Parsec'
    }
    Registry "Enable-AutoLogon-Password"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultPassword'
        ValueData = $Credential.GetNetworkCredential().Password
        ValueType = 'String'
        Force = $true
        DependsOn = '[User]User-Parsec'
    }
}
