Configuration ParsecSoftware
{
    Param()

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
        ChocolateyOptions =  @{ IgnoreChecksum = $true } # ocassionaly required between Chrome releases
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
        # DependsOn = $dependsOnList
        DependsOn = '[Script]ParsecInstallerPackage'
    }

    # Pre-configured parsec config
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
app_run_level = 1

encoder_bitrate=50
encoder_min_bitrate = 20
#encoder_vbv_max = 500
#encoder_min_qp=5

server_audio_cancel=0
network_server_start_port = 8000
server_admin_mute = 0
"@
        DependsOn = '[ChocolateyPackage]Parsec'
    }
}
