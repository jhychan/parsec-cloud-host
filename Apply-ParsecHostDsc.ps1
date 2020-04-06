[CmdletBinding()]
param()

# Script basics
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptName = Split-Path -Leaf -Path $MyInvocation.MyCommand.Definition

# Update modules and psdscresources
If(-not (Get-Module -Name PSDscResources -ListAvailable)) {
    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name PowerShellGet -Force
    Install-Module -Nam PSDscResources -Force
}

# Make parsec dsc resources available in current session
$psModulePath = $env:PSModulePath -split ';'
$psModulePath += $ScriptDir
$env:PSModulePath = ($psModulePath | Sort-Object | Get-Unique) -Join ';'

# Set up dsc local configuration manager
. .\ParsecHostLcm.ps1
ParsecHostLcm -OutputPath 'C:\ParsecHostLcm'
Set-DscLocalConfigurationManager -Path 'C:\ParsecHostLcm' -Force -Verbose

# Create dsc configuration and apply
. .\ParsecHostDsc.ps1
$configData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PsDscAllowPlainTextPassword = $true
        }
    )
}
$userCredential = Get-Credential -UserName 'parsec' -Message 'The account that will log onto this machine and run parsec:'
ParsecHostDsc -ConfigurationData $configData -OutputPath 'C:\ParsecHostDsc' -ParsecUserCredential $userCredential
# Test-DscConfiguration -Path 'C:\ParsecHostDsc'
Start-DscConfiguration -Path 'C:\ParsecHostDsc' -Force -Wait

# Prompt before restart
Restart-Computer -Confirm:$true -Verbose
