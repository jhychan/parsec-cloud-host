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
    ChocolateyPackage 'VBCable'
    {
        Ensure = 'Present'
        Name = 'vb-cable'
        Version = 'Latest'
    }

    # Nvidia driver
    $gpu = Get-SupportedGpu
    If($gpu) {
        $cloudProvider = Get-CloudProvider
        $smi = Join-Path $env:ProgramFiles 'NVIDIA Corporation\NVSMI\nvidia-smi.exe'
        If(-not (Test-Path $smi)) {
            $installerPath = Get-GpuDriver -Provider $cloudProvider -Vendor $gpu.Vendor -Device $gpu.Device -ErrorAction 'Stop'
            If($installerPath) {
                Script 'GpuDriver'
                {
                    SetScript = {
                        $proc = Start-Process -FilePath $using:installerPath -ArgumentList '/s /n' -PassThru
                        $proc | Wait-Process
                        Write-Verbose "GPU Driver Installer exit code: $($proc.ExitCode)"
                    }
                    TestScript = { Test-Path -Path $using:smi }
                    GetScript = { @{ Result = Get-Item -Path $using:smi } }
                }
            }
        }
        
        # AWS G4 has extra configs required
        $gpuDriverLookup = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot '..\..\Data\SupportedGpuDrivers.psd1')
        $gpuVendor = $gpu.Vendor
        $gpuDevice = $gpu.Device
        If($gpuDriverLookup.$cloudProvider.$gpuVendor.$gpuDevice -eq 'AWS-G4') {
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
                SetScript = {
                    $certUri = 'https://s3.amazonaws.com/nvidia-gaming/GridSwCert-Windows.cert'
                    Invoke-WebRequest -Uri $certUri -UseBasicParsing -OutFile (Join-Path $env:PUBLIC 'GridSwCert.txt')
                }
                TestScript = { Test-Path -Path (Join-Path $env:PUBLIC 'GridSwCert.txt') }
                GetScript = { @{ Result = Get-Item (Join-Path $env:PUBLIC 'GridSwCert.txt') } }
            }
        }
    }
}
