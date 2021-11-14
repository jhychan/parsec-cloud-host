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

        ParsecDrivers 'Drivers' {}

        ParsecSoftware 'Software' {}

        ParsecUser 'User'
        {
            Credential = $UserCredential
        }
    }
}
