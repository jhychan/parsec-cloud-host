Configuration Windows-User
{
	Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$Credential = Get-Credential
    )

    Import-DscResource -ModuleName 'PSDscResources'

    Node $AllNodes
    {
        
    }
}
