Configuration ParsecSoftware
{
    Param()

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'chocolatey'

    Environment 'ChocolateyInstallPath'
    {
        Ensure = 'Present'
        Name = 'ChocolateyInstall'
        Value = Join-Path $env:ProgramData 'chocolatey'
        Path = $false
        Target = 'Process','Machine'
    }
    
    ChocolateySoftware 'Chocolatey'
    {
        Ensure = 'Present'
        InstallationDirectory = $env:ChocolateyInstall
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
}
