Configuration ParsecDrivers
{
    Param()

    Import-DscResource -ModuleName 'chocolatey'

    ChocolateyPackage 'Devcon'
    {
        Ensure = 'Present'
        Name = 'devcon.portable'
        Version = 'Latest'
    }

}
