[CmdletBinding()]
param()

# Script basics
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptName = Split-Path -Leaf -Path $MyInvocation.MyCommand.Definition

# Force tls 1.2 only
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install dependencies
If(-not (Get-PackageProvider -ListAvailable -Name 'NuGet' -EA SilentlyContinue)) {
    Install-PackageProvider -Name 'NuGet' -Force -Verbose | Out-Null
}
$requiredModules = 'PowerShellGet','PSDscResources','chocolatey'
ForEach($moduleName in $requiredModules) {
    If(-not (Get-Module -ListAvailable -Name $moduleName)) {
        Install-Module -Name $moduleName -Force -Verbose | Out-Null
    }
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
$userCredential = Get-Credential -UserName 'parsec' -Message 'Account that will log onto this machine and run parsec (will be created if it does not exist):'
ParsecHostDsc -ConfigurationData $configData -OutputPath 'C:\ParsecHostDsc' -ParsecUserCredential $userCredential
# Test-DscConfiguration -Path 'C:\ParsecHostDsc'
Start-DscConfiguration -Path 'C:\ParsecHostDsc' -Force -Wait

# Prompt before restart
Restart-Computer -Confirm:$true -Verbose
