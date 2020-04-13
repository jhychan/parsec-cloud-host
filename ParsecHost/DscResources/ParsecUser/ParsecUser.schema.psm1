Configuration ParsecUser
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName 'PSDscResources'

    # Local user account running parsec
    User "Account-User-Parsec"
    {
        Ensure = 'Present'
        UserName = $Credential.UserName
        Password = $Credential
    }
    Group "Group-User-Parsec"
    {
        Ensure = 'Present'
        GroupName = 'Users'
        MembersToInclude = $Credential.UserName
        DependsOn = '[User]Account-User-Parsec'
    }
    Group "Group-Admin-Parsec"
    {
        Ensure = 'Present'
        GroupName = 'Administrators'
        MembersToInclude = $Credential.UserName
        DependsOn = '[Group]Group-User-Parsec'
    }

    # Parsec wallpaper
    $wallpaperPath = Join-Path $env:ProgramData 'ParsecHost\wallpaper.png'
    Script 'ParsecWallpaperFile'
    {
        TestScript = {
            Test-Path $using:wallpaperPath
        }
        GetScript = {
            return @{ Result = Get-Item $wallpaperPath }
        }
        SetScript = {
            $uri = 'https://s3.amazonaws.com/parseccloud/image/parsec+desktop.png'
            [System.Net.WebClient]::new().DownloadFile($uri, $using:wallpaperPath)
        }
    }
    Registry 'ParsecWallpaper'
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Desktop'
        ValueName = 'WallPaper'
        ValueData = $wallpaperPath
        ValueType = 'String'
        Force = $true
        DependsOn = '[Script]ParsecWallpaperFile','[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry 'ParsecWallpaperFill'
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Desktop'
        ValueName = 'WallPaperStyle'
        ValueData = '10'
        ValueType = 'String'
        Force = $true
        DependsOn = '[Registry]ParsecWallpaper','[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Disable IE Proxy
    Registry "IE-Proxy-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        ValueName = 'ProxyEnable'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Force close processes on shutdown
    Registry "Shutdown-Force-Kill-Processes-Enabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Desktop'
        ValueName = 'AutoEndTasks'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    
    # Disable mouse acceleration
    Registry "Mouse-Acceleration-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Mouse'
        ValueName = 'MouseSpeed'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Sensible explorer settings
    Registry "Explorer-HideRecentFiles"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        ValueName = 'ShowRecent'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-HideFrequentFolders"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        ValueName = 'ShowFrequent'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-LaunchToQuickAccess-Disabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'LaunchTo'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-ShowHiddenItems"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'Hidden'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-ShowFileExtensions"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'HideFileExt'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-HideTaskbarTaskView"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'ShowTaskViewButton'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-HideTaskbarSearch"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        ValueName = 'SearchboxTaskbarMode'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "Explorer-BestPerformanceVisuals"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
        ValueName = 'VisualFXSetting'
        ValueData = 2
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Disable accessibility keyboard shortcuts
    Registry "StickyKeysShortcutsDisabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Accessibility\StickyKeys'
        ValueName = 'Flags'
        ValueData = '506'
        ValueType = 'String'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "OSKShortcutsDisabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Accessibility\Keyboard Response'
        ValueName = 'Flags'
        ValueData = '122'
        ValueType = 'String'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }
    Registry "ToggleKeysShortcutsDisabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Control Panel\Accessibility\ToggleKeys'
        ValueName = 'Flags'
        ValueData = '58'
        ValueType = 'String'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
        PsDscRunAsCredential = $Credential
    }

    # Disable system tray hiding
    Registry "SystemTrayHidingDisabled"
    {
        Ensure = 'Present'
        Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
        ValueName = 'EnableAutoTray'
        ValueData = 0
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
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
    Registry "AutoLogon-Enabled"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'AutoAdminLogon'
        ValueData = 1
        ValueType = 'Dword'
        Force = $true
        DependsOn = '[User]Account-User-Parsec'
    }
    Registry "AutoLogon-Domain"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultDomainName'
        ValueData = '.'
        ValueType = 'String'
        Force = $true
        DependsOn = '[User]Account-User-Parsec'
    }
    Registry "AutoLogon-Username"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultUserName'
        ValueData = $Credential.UserName
        ValueType = 'String'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
    }
    Registry "AutoLogon-Password"
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
        ValueName = 'DefaultPassword'
        ValueData = $Credential.GetNetworkCredential().Password
        ValueType = 'String'
        Force = $true
        DependsOn = '[Group]Group-Admin-Parsec'
    }
}
