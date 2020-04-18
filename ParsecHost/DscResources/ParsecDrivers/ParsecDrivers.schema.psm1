Import-Module -Name (Join-Path $PSScriptRoot 'GpuHelper.psm1')

Configuration ParsecDrivers
{
    Param()

    Import-DscResource -ModuleName 'chocolatey'
    Import-DscResource -ModuleName 'PSDscResources'

    ChocolateyPackage 'Devcon'
    {
        Ensure = 'Present'
        Name = 'devcon.portable'
        Version = 'Latest'
    }

    # Virtual audio driver - https://www.vb-audio.com/Cable
    ServiceSet 'AudioServices'
    {
        Name = 'Audiosrv','AudioEndpointBuilder'
        StartupType = 'Automatic'
        State = 'Running'
    }
    $chocolateyInstallPath = Join-Path $env:ProgramData 'chocolatey'
    $packageName = 'vbcable'
    $packageVersion = '1.0'
    $packageSourceFolder = Join-Path $chocolateyInstallPath 'local'
    $packageFolder = Join-Path $packageSourceFolder $packageName
    File 'VBCableInstallerPackageSource'
    {
        Ensure = 'Present'
        DestinationPath = $packageFolder
        Type = 'Directory'
    }

    $packageFile = "$packageName.$packageVersion.nupkg"
    $packageFilePath = Join-Path $packageFolder $packageFile
    $packageNuspec = Join-Path $PSScriptRoot "..\..\Packages\$packageName\$packageName.nuspec"
    Script 'VBCableInstallerPackage'
    {
        TestScript = {
            Test-Path -Path $using:packageFilePath
        }
        GetScript = {
            @{ Result = Get-Item $using:packageFilePath }
        }
        SetScript = {
            choco.exe pack $using:packageNuspec --outputdirectory $using:packageFolder
        }
        DependsOn = '[File]VBCableInstallerPackageSource'
    }
    ChocolateyPackage 'VBCable'
    {
        Ensure = 'Present'
        Name = 'vbcable'
        Version ='Latest'
        ChocolateyOptions = @{
            'source' = $packageSourceFolder
        }
        DependsOn = '[ServiceSet]AudioServices','[Script]VBCableInstallerPackage'
    }

    # Nvidia driver
    $gpu = Get-SupportedGpu
    If($gpu)
    {
        $cloudProvider = Get-CloudProvider
        $smi = Join-Path $env:ProgramFiles 'NVIDIA Corporation\NVSMI\nvidia-smi.exe'
        If(-not (Test-Path $smi))
        {
            $driverInstaller = Download-GpuDriver -Provider $cloudProvider -Vendor $gpu.Vendor -Device $gpu.Device -ErrorAction 'Stop'
            If($driverInstaller)
            {
                Script 'GpuDriver'
                {
                    TestScript = {
                        Test-Path -Path $using:smi
                    }
                    GetScript = {
                        @{ Result = Get-Item -Path $using:smi }
                    }
                    SetScript = {
                        $proc = Start-Process -FilePath $using:driverInstaller -ArgumentList '/s /n' -PassThru
                        $proc | Wait-Process
                        Write-Verbose "GPU Driver Installer exit code: $($proc.ExitCode)"
                    }
                }
            }
        }
        
        # AWS G4 has extra configs required
        If($gpuDriverLookup.$cloudProvider.$($gpu.Vendor).$($gpu.Device) -eq 'AWS-G4')
        {
            # https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html#nvidia-gaming-driver
            Registry 'AWSG4vGamgingMarketplace'
            {
                Ensure = 'Present'
                Key = 'HKLM:\SOFTWARE\NVIDIA Corporation\Global'
                ValueName = 'vGamingMarketplace'
                ValueData = 2
                ValueType = 'Dword'
                Force = $true
            }
            Script 'AWSG4Certificate'
            {
                TestScript = {
                    Test-Path -Path (Join-Path $env:PUBLIC 'GridSwCert.txt')
                }
                GetScript = {
                    @{ Result = Get-Item (Join-Path $env:PUBLIC 'GridSwCert.txt') }
                }
                SetScript = {
                    $certUri = 'https://s3.amazonaws.com/nvidia-gaming/GridSwCert-Windows.cert'
                    Invoke-WebRequest -Uri $certUri -UseBasicParsing -OutFile (Join-Path $env:PUBLIC 'GridSwCert.txt')
                }
            }
        }
    }
}
