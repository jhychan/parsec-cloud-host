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
Write-Host -ForegroundColor 'Green' 'Checking DSC dependencies'
If(-not (Get-PackageProvider -ListAvailable -Name 'NuGet' -EA SilentlyContinue)) {
    Install-PackageProvider -Name 'NuGet' -Force -Verbose | Out-Null
}
$requiredModules = 'PowerShellGet','PSDscResources','ComputerManagementDsc','chocolatey'
ForEach($moduleName in $requiredModules) {
    If(-not (Get-Module -ListAvailable -Name $moduleName)) {
        Install-Module -Name $moduleName -Force -Verbose | Out-Null
    }
}

# Make parsec module and dsc resources available in current session
Write-Host -ForegroundColor 'Green' 'Adding ParsecHost module to PowerShell search paths'
$psModulePath = $env:PSModulePath -split ';'
$psModulePath += $PSScriptRoot
$env:PSModulePath = ($psModulePath | Sort-Object | Get-Unique) -Join ';'
Import-Module -Name 'ParsecHost' -Force

# Set up dsc local configuration manager
Write-Host -ForegroundColor 'Green' 'Applying Local Configuration Manager settings'
$lcmPath = Join-Path $env:ProgramData 'ParsecHost\Lcm'
. $PSScriptRoot\ParsecHostLcm.ps1
ParsecHostLcm -OutputPath $lcmPath | Out-Null
Set-DscLocalConfigurationManager -Path $lcmPath -Force

# Create dsc configuration and apply
Write-Host -ForegroundColor 'Green' 'Applying Parsec Host settings'
. $PSScriptRoot\ParsecHostDsc.ps1
$configData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PsDscAllowPlainTextPassword = $true
        }
    )
}
If ($global:userCredential -isnot [PSCredential]) {
    Write-Host -ForegroundColor 'Green' 'Prompting for new/existing autologon user account'
    $global:userCredential = Get-Credential -UserName 'parsecuser' -Message 'Account that will autologon and run parsec (if account already exists password will be updated)'
} Else {
    Write-Host -ForegroundColor 'Green' "Reusing previously provided user account ($($global:userCredential.UserName))"
}

$dscPath = Join-Path $env:ProgramData 'ParsecHost\Dsc'
ParsecHostDsc -ConfigurationData $configData -OutputPath $dscPath -ParsecUserCredential $global:userCredential | Out-Null
Start-DscConfiguration -Path $dscPath -Force -Wait

# Prompt user to login to parsec (should already be running)
Write-Host -ForegroundColor 'Green' 'Start parsec (if not already running), log in and configure settings and make sure hosting is enabled.'
Read-Host -Prompt 'Hit [enter] to continue...' | Out-Null

# Prompt before restart
Write-Host -ForegroundColor 'Green' "At next reboot this machine will automatically log on as $($userCredential.UserName) and be ready to connect remotely via Parsec client."
$reboot = Read-Host -Prompt 'Ready to reboot? (y/n)'
if ($reboot -eq 'y') {
    Write-Host -ForegroundColor 'Green' 'Rebooting...'
    Restart-Computer -Confirm:$false
} else {
    Write-Host -ForegroundColor 'Green' 'Skipping reboot. Please reboot the machine manually to complete configuration.'
}
