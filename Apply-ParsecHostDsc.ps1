#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param()

# Script flow control
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
$psModulePath += $PSScriptRoot
$env:PSModulePath = ($psModulePath | Sort-Object | Get-Unique) -Join ';'
Import-Module -Name 'ParsecHost' -Force

# Set up dsc local configuration manager
$lcmPath = Join-Path $env:ProgramData 'ParsecHost\Lcm'
. .\ParsecHostLcm.ps1
ParsecHostLcm -OutputPath $lcmPath
Set-DscLocalConfigurationManager -Path $lcmPath -Force

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
If($global:userCredential -isnot [PSCredential]) {
    $global:userCredential = Get-Credential -UserName 'parsec' -Message 'Account that will log onto this machine and run parsec (will be created if it does not exist):'
}

$dscPath = Join-Path $env:ProgramData 'ParsecHost\Dsc'
ParsecHostDsc -ConfigurationData $configData -OutputPath $dscPath -ParsecUserCredential $global:userCredential
Start-DscConfiguration -Path $dscPath -Force -Wait

# Prompt before restart
Restart-Computer -Confirm:$true -Verbose
