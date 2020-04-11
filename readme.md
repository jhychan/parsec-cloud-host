# Parsec Cloud Host using PowerShell DSC
Configure a cloud-hosted parsec VM in using PowerShell DSC.

Largly based on the [Parsec Cloud Preparation Tool](https://github.com/jamesstringerparsec/Parsec-Cloud-Preparation-Tool).

# Status
Still in a very alpha state, so not quite on par with the Parsec Cloud Preparation Tool. Nvidia driver install and parsec post-install config are the key functions still being worked on.

# How to use this
1. Build a Window Server 2016 or Server 2019 machine. This module supports:
 - Azure (M60)
 - AWS (K520, M60, P4, T4)
 - GCP (P4, T4)
 - Paperspace (P4000, P5000)
 - Anything else (you have to manually install NVidia drivers)
2. Start PowerShell with **administrator** privileges, then run the following (you can copy paste the entire block including comments):
```powershell
# Force TLS 1.2, allow arbitrary script execution just for this session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy 'Bypass' -Scope 'Process' -Force

# Set some paths
$workingDir = $env:Temp
$zipFile = Join-Path $workingDir 'parsec-cloud-host.zip'
$extractedPath = Joi-Path $workingDir 'parsec-cloud-host-master'

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


# Staus of Configuration Items
## Windows Features:
 - [x] .Net 3.5 Framework
 - [x] .Net 4.x Framework
 - [x] Direct-Play

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
 - [x] Configure user account
 	- [x] autologon configured
 - [x] Disable IE proxy settings
 - [x] Automatically close apps on shutdown
 - [x] Disable mouse acceleration
 - [x] Windows explorer settings
    - [x] Show hidden files
    - [x] Show file extensions
 	- [x] Disable recent files
 - [x] Desktop settings
 	[ ] Set wallpaper

## Install Software:
 - [x] PowerShell modules
 	- [x] Chocolatey
 	- [x] PSDscResources
 - [x] General Software
 	- [x] 7zip
 	- [x] Google Chrome
 	- [x] Parsec
 	   - [ ] Parsec autostartup (as a service)
 	   - [ ] Prompt for logging in
 	   - [ ] Pre-configure settings
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
