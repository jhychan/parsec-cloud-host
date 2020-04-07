Configuration ParsecSoftware
{
    Param()

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'chocolatey'

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

    # Configure parsec autorun for all users
    $parsecFilePath = Join-Path $env:ProgramFiles 'Parsec\parsecd.exe'
    Registry 'ParsecAutorun'
    {
        Ensure = 'Present'
        Key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
        ValueName = 'Parsec.App.0'
        ValueData = "$parsecFilePath app_silent=1"
        ValueType = 'String'
        DependsOn = '[ChocolateyPackage]Parsec'
    }
}
