Configuration ParsecSoftware
{
    Param()

    Import-DscResource -ModuleName 'chocolatey'

    ChocolateySoftware 'Chocolatey'
    {
        Ensure = 'Present'
    }

    ChocolateyPackage '7zip'
    {
        Ensure = 'Present'
        Name = '7zip'
        Version = 'Latest'
    }

    ChocolateyPackage 'Chrome'
    {
        Ensure = 'Present'
        Name = 'googlechrome'
        Version = 'Latest'
    }
}
