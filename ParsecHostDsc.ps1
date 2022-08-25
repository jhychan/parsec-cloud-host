Configuration ParsecHostDsc
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$UserCredential
    )

    Import-DscResource -ModuleName 'ParsecHost'

    Node 'localhost'
    {
        ParsecSystem 'System' {}

        ParsecSoftware 'Software' {}

        ParsecDrivers 'Drivers'
        {
            DependsOn = '[ParsecSoftware]Software'
        }

        ParsecUser 'User'
        {
            Credential = $UserCredential
        }
    }
}
