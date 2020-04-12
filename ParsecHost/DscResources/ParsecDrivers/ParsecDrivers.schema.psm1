Import-Moudule -Name "$PSScriptRoot\GpuHelper.psm1"


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
            # $downloadedFile = Download-GpuDriver -Provider $cloudProvider -Vendor $gpu.Vendor -Device $gpu.Device -ErrorAction 'Stop'
            If($downloadedFile) {
                Script 'GpuDriver'
                {
                    TestScript = {
                        Test-Path -Path $using:smi
                    }
                    GetScript = {
                        @{ Result = Get-Item -Path $using:smi }
                    }
                    SetScript = {
                        $proc = Start-Process -FilePath $using:downloadedFile -ArgumentList '/s /n' -PassThru
                        $proc | Wait-Process
                        Write-Verbose "GPU Driver Installer exit code: $($proc.ExitCode)"
                    }
                }
            }
        }
        
        # AWS G4 has extra configs required
        If($gpuDriverLookup.$cloudProvider.$($gpu.Vendor).$($gpu.Device) -eq 'AWS-G4') {
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
