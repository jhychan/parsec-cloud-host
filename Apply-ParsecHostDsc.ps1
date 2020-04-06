#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param()

# Script basics
$ScriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ScriptName = Split-Path -Leaf -Path $MyInvocation.MyCommand.Definition
$ErrorActionPreference = 'Stop'

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
$lcmPath = Join-Path $env:ProgramData 'ParsecHost\Lcm'
. .\ParsecHostLcm.ps1
ParsecHostLcm -OutputPath $lcmPath
Set-DscLocalConfigurationManager -Path $lcmPath -Force -Verbose

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
$dscPath = Join-Path $env:ProgramData 'ParsecHost\Dsc'
ParsecHostDsc -ConfigurationData $configData -OutputPath $dscPath -ParsecUserCredential $userCredential
Start-DscConfiguration -Path $dscPath -Force -Wait

# Prompt before restart
Restart-Computer -Confirm:$true -Verbose
