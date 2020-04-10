Configuration ParsecHostDsc
{
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ParsecUserCredential
    )

    Import-DscResource -ModuleName 'ParsecHost'

    Node 'localhost'
    {
        ParsecSystem 'System' {}

        ParsecUser 'User'
        {
            Credential = $ParsecUserCredential
            DependsOn = '[ParsecSystem]System'
        }

        # ParsecSoftware 'Software'
        # {
        #     DependsOn = '[ParsecUser]User'
        # }

        # ParsecDrivers 'Drivers'
        # {
        #     DependsOn = '[ParsecSoftware]Software'
        # }
    }
}
