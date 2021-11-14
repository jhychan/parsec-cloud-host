#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param()

# Script flow control
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Force tls 1.2 only
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install dependencies
'Checking DSC dependencies' | Write-Host -ForegroundColor 'Green'
If(-not (Get-PackageProvider -ListAvailable -Name 'NuGet' -EA SilentlyContinue)) {
    Install-PackageProvider -Name 'NuGet' -Force -Verbose | Out-Null
}
$requiredModules = 'PowerShellGet','PSDscResources','ComputerManagementDsc','chocolatey','DeviceManagement'
ForEach($moduleName in $requiredModules) {
    If(-not (Get-Module -ListAvailable -Name $moduleName)) {
        Install-Module -Name $moduleName -Force -Verbose | Out-Null
    }
}

# Make parsec module and dsc resources available in current session
'Adding ParsecHost DSC module to PowerShell search paths' | Write-Host -ForegroundColor 'Green'
$psModulePath = $env:PSModulePath -split ';'
$psModulePath += $PSScriptRoot
$env:PSModulePath = ($psModulePath | Sort-Object | Get-Unique) -Join ';'
Import-Module -Name 'ParsecHost' -Force

# Set up dsc local configuration manager
'Applying Local Configuration Manager settings' | Write-Host -ForegroundColor 'Green'
$lcmPath = Join-Path $env:ProgramData 'ParsecHost\Lcm'
. $PSScriptRoot\ParsecHostLcm.ps1
ParsecHostLcm -OutputPath $lcmPath | Out-Null
Set-DscLocalConfigurationManager -Path $lcmPath -Force

# prompts for the local user account/profile that will hosting parsec sessions
If ($global:userCredential -isnot [PSCredential]) {
    'Currently logged in as {0} - please provide logon credentials for DSC to configure user settings' -f $env:USERNAME | Write-Host -ForegroundColor 'Green'
    $global:userCredential = Get-Credential -UserName $env:USERNAME -Message 'Please enter your credentials'
} Else {
    'Using previously provided user account {0} for configuring user settings' -f $global:userCredential.UserName | Write-Host -ForegroundColor 'Green'
}

# Create dsc configuration and apply
'Applying Parsec Host settings' | Write-Host -ForegroundColor 'Green'
$configData = @{ AllNodes = @( @{ NodeName = 'localhost'; PsDscAllowPlainTextPassword = $true } ) }
$dscPath = Join-Path $env:ProgramData 'ParsecHost\Dsc'
. $PSScriptRoot\ParsecHostDsc.ps1
ParsecHostDsc -ConfigurationData $configData -OutputPath $dscPath -UserCredential $global:userCredential | Out-Null
Start-DscConfiguration -Path $dscPath -Force -Wait

# Prompt user to login to parsec (should already be running)
'Start parsec, log in, configure settings and make sure hosting is enabled.' | Write-Host -ForegroundColor 'Green'
Read-Host -Prompt 'Hit [enter] to continue...' | Out-Null

# Prompt before restart
'Setup complete!' | Write-Host -ForegroundColor 'Green'
$reboot = Read-Host -Prompt 'Ready to reboot? (y/n)'
if ($reboot -eq 'y') {
    'Rebooting...' | Write-Host -ForegroundColor 'Green'
    Restart-Computer -Confirm:$false
} else {
    'Skipping reboot. Please reboot the machine manually to complete configuration.' | Write-Host -ForegroundColor 'Green'
}
