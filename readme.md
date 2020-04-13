# Configure Parsec Host using PowerShell DSC
This module configures a cloud-based parsec host using [PowerShell Desired State Configuration](https://docs.microsoft.com/en-us/powershell/scripting/dsc/getting-started/wingettingstarted?view=powershell-5.1). Much of the configuration is based off the [Parsec Cloud Preparation Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool). While there is no requirement for the machine to be cloud hosted, this configuration applies a number of Windows settings that you probably shouldn't have on a local primary machine (ie. autologon).

# What this does
This module will automatically tweak Windows system settings, create a local account for autologon and set its password (or update the password of an existing local account), tweak user settings, install some software and drivers and configure parsec within a single reboot (you will still need to log in to parsec manually first before rebooting). At the next reboot your chosen account will autologon and parsec hosting session will be automatically started and ready to accept connections. The GPU driver installation steps are still a work in progress.

# How to use this
## Build a machine
This module has been developed to simplfy the deployment of parsec to cloud-hosted Window 10 or Windows Server 2016/2019 VMs with NVIDIA GPUs. While this is not a hard requirement, for the module to work correctly your choice of Windows must have PowerShell 5.1 or higher installed/available, and of course for Parsec's minimum requirements to be met.

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

Parsec configuration file is set to host from port UDP 8000, so make sure you have opened up an appropriately sized UDP port range on the virtual network to your parsec host VM.

## Apply the Configuration
Connect to your machine using RDP (remote desktop). Start PowerShell with **administrator** privileges, then copy-and-paste the following commands:
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
The checklist below outlines the configuration applied by this module, and tracks configuration capabilities that are under development.

## Windows Features:
 - [x] .Net 3.5 Framework
 - [x] .Net 4.x Framework
 - [x] DirectPlay

## Windows General:
 - [x] Disable IE ESC
 - [x] Disable Automatic Updates (Windows)
 - [x] Enable automatic NTP sync
 - [x] Disable New Network window
 - [x] Prioritise foreground processes
 - [x] Disable Server Manager at logon
 - [x] Disable crash dump
 - [x] Disable lockscreen
 - [x] Disable unncessary services
 - [x] Disable unncessary scheduled tasks
 - [x] Disable telemetry
 - [x] Switch to high performance power plan

## Windows User:
 - [x] Configure local user account with autologon
 - [x] Disable IE proxy settings
 - [x] Automatically close apps on shutdown
 - [x] Disable mouse acceleration
 - [x] Disable accessibility keyboard shortcuts
 - [x] Set visual settings to best performance
 - [x] Windows explorer settings
    - [x] Show hidden files
    - [x] Show file extensions
 	- [x] Disable recent files
 - [x] Desktop settings
 	- [x] Set wallpaper
  - [x] Disable system tray hiding

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

## Install Drivers:
 - [x] devcon
 - [x] VB-Cable
 	- [x] Windows audio services
 - [ ] Nvidia GPU
 	- [ ] Enable NVidia GPU
 	- [ ] Disable all other GPUs
 	- [ ] Allow only one monitor
 	- [ ] Check GRID mode
 - [ ] Unsupported GPUs
    - [ ] Warn user about parsec compat and manual driver install
