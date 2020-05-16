Configuration ParsecSoftware
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName 'chocolatey'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'PSDscResources'

    $chocolateyInstallPath = Join-Path $env:ProgramData 'chocolatey'
    Environment 'ChocolateyInstallPath'
    {
        Ensure = 'Present'
        Name = 'ChocolateyInstall'
        Value = $chocolateyInstallPath
        Path = $false
        Target = 'Process','Machine'
    }

    ChocolateySoftware 'Chocolatey'
    {
        Ensure = 'Present'
        InstallationDirectory = $chocolateyInstallPath
        DependsOn = '[Environment]ChocolateyInstallPath'
    }

    ChocolateyPackage '7zip'
    {
        Ensure = 'Present'
        Name = '7zip'
        Version = 'Latest'
        DependsOn = '[ChocolateySoftware]Chocolatey'
    }

    ChocolateyPackage 'Chrome'
    {
        Ensure = 'Present'
        Name = 'googlechrome'
        Version = 'Latest'
        DependsOn = '[ChocolateySoftware]Chocolatey'
    }

    # Who doesn't love steam ;)
    ChocolateyPackage 'Steam'
    {
        Ensure = 'Present'
        Name = 'steam'
        Version = 'Latest'
        DependsOn = '[ChocolateySoftware]Chocolatey'
    }

    # Set up shared parsec config directory
    $currentConfigDir = Join-Path $env:ProgramData 'Parsec'
    $currentConfigPath = Join-Path $currentConfigDir 'config.txt'
    File 'ParsecConfigFile'
    {
        Ensure = 'Present'
        DestinationPath = $currentConfigPath
        Type = 'File'
        Contents = @"
# All configuration settings must appear on a new line.
# All whitespace, besides the newline character '\n', is ignored.
# All settings passed via the command line take precedence.
# The configuration file will be overwritten by Parsec when changing settings,
#   so if you edit this file while Parsec is running, make sure to save this file
#   and restart Parsec immediately so your changes are preserved.

# Example:
# encoder_bitrate = 10
app_run_level = 3

encoder_bitrate=50
encoder_min_bitrate = 20
#encoder_vbv_max = 500
#encoder_min_qp=5

server_audio_cancel=0
network_server_start_port = 8000
"@
    }

    # Symlink the config directory for all enabled users
    $users = Get-LocalUser | ? { $_.Enabled }
    ForEach($username in $users.Name) {
        $parsecConfigDir = Join-Path $env:SystemDrive "Users\$username\AppData\Roaming\Parsec"
        Script "ParsecUserConfigFolder$username"
        {
            TestScript = {
                # if folder exists then do nothing - either already hardlinked, or current session is the autologon account
                Test-Path $using:parsecConfigDir
            }
            GetScript = {
                @{ Result = Get-Item $using:parsecConfigDir }
            }
            SetScript = {
                New-Item -ItemType 'Junction' -Path $using:parsecConfigDir -Value $using:currentConfigDir
            }
            Dependson = '[File]ParsecConfigFile'
        }
    }
    $dependsOnList = $users.Name | % { "[Script]ParsecUserConfigFolder$username" }

    # Generated parsec chocolatey package
    $packageName = 'parsecgaming'
    $packageVersion = '1.0'
    $packageSourceFolder = Join-Path $chocolateyInstallPath 'local'
    $packageFolder = Join-Path $packageSourceFolder $packageName
    File 'ParsecInstallerPackageSource'
    {
        Ensure = 'Present'
        DestinationPath = $packageFolder
        Type = 'Directory'
        DependsOn = '[ChocolateySoftware]Chocolatey'
    }

    $packageFile = "$packageName.$packageVersion.nupkg"
    $packageFilePath = Join-Path $packageFolder $packageFile
    $packageNuspec = Join-Path $PSScriptRoot "..\..\Packages\$packageName\$packageName.nuspec"
    Script 'ParsecInstallerPackage'
    {
        TestScript = {
            Test-Path -Path $using:packageFilePath
        }
        GetScript = {
            @{ Result = Get-Item $using:packageFilePath }
        }
        SetScript = {
            choco.exe pack $using:packageNuspec --outputdirectory $using:packageFolder
        }
        DependsOn = '[ChocolateySoftware]Chocolatey','[File]ParsecInstallerPackageSource'
    }

    # Install parsec using the generated package
    ChocolateyPackage 'Parsec'
    {
        Ensure = 'Present'
        Name = 'parsecgaming'
        Version ='Latest'
        ChocolateyOptions = @{
            'source' = $packageSourceFolder
        }
        DependsOn = '[Script]ParsecInstallerPackage' + $dependsOnList
    }

    # Configure parsec autolaunch via scheduled task for the logged in user
    $parsecScheduledTaskName = 'Parsec'
    $parsecFilePath = Join-Path $env:ProgramFiles 'Parsec\parsecd.exe'
    $dummyPassword = ConvertTo-SecureString -AsPlainText -String ' ' -Force
    $builtinUsers = [PSCredential]::New('Users',$dummyPassword)
    ScheduledTask 'ParsecAutorun'
    {
        Ensure = 'Present'
        TaskName = $parsecScheduledTaskName
        ExecuteAsCredential = $builtinUsers
        LogonType = 'Group'
        RunLevel = 'Highest'
        ScheduleType = 'AtLogOn'
        ActionExecutable = $parsecFilePath
        MultipleInstances = 'IgnoreNew'
        DependsOn = '[ChocolateyPackage]Parsec'
    }

    # Use scheduled task to launch parsec in current session for setting up login
    Script 'ParsecRunning'
    {
        TestScript = {
            (Get-Process -Name 'parsecd' -EA 'SilentlyContinue') -ne $null
        }
        GetScript = {
            @{ Result = Get-Process -Name 'parsecd' -EA 'SilentlyContinue' }
        }
        SetScript = {
            Start-ScheduledTask -TaskName $using:parsecScheduledTaskName
            Start-Sleep -Seconds 5
        }
        DependsOn = '[ScheduledTask]ParsecAutorun'
    }
}
