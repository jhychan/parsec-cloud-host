# Parsec Cloud Host using PowerShell DSC
Configure a cloud-hosted parsec machine in using PowerShell DSC.

Largly based on the [Parsec Cloud Preparation Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool).

There is no requirement for the machine to be cloud hosted - it could just as well be a physical machine elsewhere in your home.

# Status
Still in a very alpha state, so not quite on par with the Parsec Cloud Preparation Tool. Nvidia driver install and parsec post-install config are the key functions still being worked on.

# How to use this
## Build a machine
This module is targeted at Window Server 2016/2019 machines. This requirement is soft however - the functional requirement is for DSC 5.0 and above which is only available on machines that have Windows Management Framework 5.1 and above. This means the module should support Windows 10 as well (not tested).

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
 - Anything else
   - You will have to manually install GPU drivers

## Apply the Configuration
**Before proceeding, please make sure you install the latest Windows Updates on the machine**

Start PowerShell with **administrator** privileges, then copy-and-paste the following command block:
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
The checklist below summaries the configuration that is made by this module. This is also where you can track what configuration capabilities are being worked on.

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
 - [ ] Timed usaged warnings

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
 	- [ ] Set wallpaper

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
 	   - [x] Symlink parsec config folder to the autologon accoun
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
