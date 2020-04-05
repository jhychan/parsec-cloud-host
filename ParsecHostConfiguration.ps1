$configData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Credential = Get-Credential -UserName $env:USERNAME -Message 'Enter the local credentials for autologon'
        }
    )
}


Configuration ParsecHostConfiguration
{
	Param()

	Import-DscResource -ModuleName '.\Resources'

	Node 'localhost'
	{
		
	}
}
