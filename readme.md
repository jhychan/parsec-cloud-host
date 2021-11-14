# Configure Parsec Host using PowerShell DSC
This module configures a cloud-based parsec host using [PowerShell Desired State Configuration](https://docs.microsoft.com/en-us/powershell/scripting/dsc/getting-started/wingettingstarted?view=powershell-5.1). Much of the configuration is based off the [Parsec Cloud Preparation Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool).

# What this does
This module will automatically set number of Windows system settings, user settings, install some software and drivers and configure parsec within a single reboot. Parsec is installed in Shared mode, so you will need to log in to parsec manually first before rebooting.

# How to use this
## Build a machine
This module is intended to prepare a parsec cloud-hosted Window 10 or Windows Server 2016/2019 VMs with NVIDIA GPU. While the OS version is not strictly required, your choice of Windows must have PowerShell 5.1 or higher installed/available, and of course for Parsec's minimum requirements to be met.

Cloud provider and GPU list:
 - Azure
   - Tesla M60
 - AWS
   - GRID K520
   - Tesla M60
   - Tesla P4
   - Tesla T4
   - A10G
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
$branch = 'master'
$workingDir = $env:Temp
$zipFile = Join-Path $workingDir 'parsec-cloud-host.zip'
$extractedPath = Join-Path $workingDir "parsec-cloud-host-$branch"

# Clean up any previous runs
Remove-Item -Path $zipFile -EA SilentlyContinue
Remove-Item -Recurse -Path $extractedPath -EA SilentlyContinue

# Download zip of the repo and extract
[System.Net.WebClient]::new().DownloadFile("https://github.com/jhychan/parsec-cloud-host/archive/refs/heads/$branch.zip", $zipFile)
Get-Item $zipFile | Expand-Archive -DestinationPath $workingDir

# Apply the configuration
Set-Location -Path $workingDir
.\parsec-cloud-host-$branch\Apply-ParsecHostDsc.ps1 -Verbose
```

The script will proceed to configure the machine. You should be prompted for the following:
* Login to Parsec after it has been installed
* Reboot the machine after all provising tasks are complete

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
 - [x] ~~Configure local user account with autologon~~
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
  - [x] DeviceManagement
 - [x] General Software
 	- [x] 7zip
 	- [x] Google Chrome
 	- [x] Parsec
 	   - [x] ~~Parsec autostartup (as a scheduled task)~~
 	   - [x] User message to login and configure parsec
 	   - [x] ~~Symlink parsec config folder to the autologon account~~
 	   - [x] Set default hosting port to start from 8000
 	- [x] Steam

## Install Drivers:
 - [x] devcon
 - [x] VB-Cable
 	- [x] Windows audio services
 - [x] Nvidia GPU (needs testing)
 	- [x] Enable NVidia GPU (vGaming/Grid licensing)
 	- [x] Disable basic display adapters
 - [x] Unsupported GPUs
    - [x] Warn user about parsec compat and manual driver install
