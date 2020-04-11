# Configure Parsec Host using PowerShell DSC
This module configures a parsec host machine using PowerShell DSC. Most of the work here is based off the hard work done by the author of the [Parsec Cloud Preparation Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool). There is no requirement for the machine to be cloud hosted - this module can be applied to any machine you want configured as a parsec host.

# Status
Still in a very alpha state, so not yet on par with the Parsec Cloud Preparation Tool. Nvidia driver install and parsec post-install config are the key functions still being worked on.

# How to use this
## Build a machine
This module has been developed to simplfy the deployment of parsec to cloud-hosted Window 10 or Windows Server 2016/2019 VMs with NVIDIA GPUs. However there is no hard requirement for the machine to be cloud hosted, nor for the machine to be limited to those versions of Windows and GPUs. The only technical requirement for this module to work correctly is that your choice of Windows must have PowerShell 5.1 or higher installed/available, and of course for Parsec's minimum requirements to be met.

Cloud provider and GPU list:
 - Azure
   - Tesla M60
 - AWS
   - GRID K520
   - Tesla M60
   - Tesla P4
   - Tesla T4
 - Google Cloud
   - Tesla P4
   - Tesla T4
 - Paperspace
   - Quadro P4000
   - Quadro P5000
 - Other
   - You will have to manually install GPU drivers

## Apply the Configuration
Connect to your machine using RDP (remote desktop). Start PowerShell with **administrator** privileges, then copy-and-paste the following command block:
```powershell
# Force TLS 1.2, allow arbitrary script execution just for this session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy 'Bypass' -Scope 'Process' -Force

# Set some paths
$workingDir = $env:Temp
$zipFile = Join-Path $workingDir 'parsec-cloud-host.zip'
$extractedPath = Join-Path $workingDir 'parsec-cloud-host-master'

# Clean up any previous runs
Remove-Item -Path $zipFile -EA SilentlyContinue
Remove-Item -Recurse -Path $extractedPath -EA SilentlyContinue

# Download zip of the repo and extract
[System.Net.WebClient]::new().DownloadFile('https://github.com/jhychan/parsec-cloud-host/archive/master.zip', $zipFile)
Get-Item $zipFile | Expand-Archive -DestinationPath $workingDir

# Apply the configuration
Set-Location -Path $workingDir
.\parsec-cloud-host-master\Apply-ParsecHostDsc.ps1 -Verbose
```


# Progress Tracker
The checklist below summaries the configuration that is made by this module. This is also where you can track what configuration capabilities are under development.

## Windows Features:
 - [x] .Net 3.5 Framework
 - [x] .Net 4.x Framework
 - [x] DirectPlay

## Windows General:
 - [x] Disable IE ESC
 - [x] Disable Automatic Updates (Windows)
 - [x] Enable automatic NTP sync
 - [x] Disable New Network window
 - [x] Disable Server Manager at logon
 - [x] Disable lockscreen
 - [ ] Auto-shutdown on idle
 - [ ] Timed usage warnings

## Windows User:
 - [x] Configure local user account with autologon
 - [x] Disable IE proxy settings
 - [x] Automatically close apps on shutdown
 - [x] Disable mouse acceleration
 - [x] Windows explorer settings
    - [x] Show hidden files
    - [x] Show file extensions
 	- [x] Disable recent files
 - [x] Desktop settings
 	- [x] Set wallpaper

## Install Software:
 - [x] PowerShell modules
 	- [x] Chocolatey
 	- [x] PSDscResources
 - [x] General Software
 	- [x] 7zip
 	- [x] Google Chrome
 	- [x] Parsec
 	   - [x] Parsec autostartup (as a scheduled task)
 	   - [x] User message to login and configure parsec
 	   - [x] Symlink parsec config folder to the autologon account
 	   - [x] Set default hosting port to start from 8000
 	- [x] Steam
 	   - [ ] Prompt for logging in
 	   - [ ] Fix save-credentials

## Install Drivers:
 - [x] devcon
 - [x] VB-Cable
 - [ ] Nvidia GPU
 	- [ ] Enable NVidia GPU
 	- [ ] Disable all other GPUs
 	- [ ] Allow only one monitor
 	- [ ] Check GRID mode
 - [ ] Unsupported GPUs
    - [ ] Warn user about parsec compat and manual driver install
