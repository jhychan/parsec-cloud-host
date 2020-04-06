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
		ParsecSystem 'ParsecSystem' {}
        ParsecUser 'ParsecUser'
        {
            Credential = $ParsecUserCredential
        }
	}
}
