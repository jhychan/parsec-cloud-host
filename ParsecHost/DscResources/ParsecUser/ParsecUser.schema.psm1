Configuration ParsecUser
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName 'PSDscResources'

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
        DependsOn = '[Script]ParsecWallpaperFile'
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
        DependsOn = '[Registry]ParsecWallpaper'
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
        PsDscRunAsCredential = $Credential
    }
}
