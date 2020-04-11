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
        SetScript = { choco.exe pack $using:packageNuspec --outputdirectory $using:packageFolder }
        TestScript = { Test-Path -Path $using:packageFilePath }
        GetScript = { @{ Result = Get-Item $using:packageFilePath } }
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
        DependsOn = '[Script]ParsecInstallerPackage'
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
        SetScript = {
            Start-ScheduledTask -TaskName $using:parsecScheduledTaskName
            Start-Sleep -Seconds 5
        }
        TestScript = { (Get-Process -Name 'parsecd' -EA 'SilentlyContinue') -ne $null }
        GetScript = { @{ Result = Get-Process -Name 'parsecd' -EA 'SilentlyContinue' } }
        DependsOn = '[ScheduledTask]ParsecAutorun'
    }

    # Current user might not be the autologon user - hardlink the parsec config dir if not
    $parsecConfigDir = Join-Path $env:SystemDrive "Users\$($Credential.UserName)\AppData\Roaming\Parsec"
    $currentConfigDir = Join-Path $env:AppData "Parsec"
    Script 'ParsecUserConfigFolder'
    {
        SetScript = {
            New-Item -ItemType 'Junction' -Path $using:parsecConfigDir -Value $using:currentConfigDir
        }
        TestScript = {
            # if folder exists then do nothing - either already hardlinked, or current session is the autologon account
            Test-Path $using:parsecConfigDir
        }
        GetScript = {
            @{ Result = Get-Item $using:parsecConfigDir }
        }
        Dependson = '[Script]ParsecRunning'
    }
}
