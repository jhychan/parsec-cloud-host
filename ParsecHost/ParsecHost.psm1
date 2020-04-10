Function Test-CloudProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateSet('AWS','Azure','GCP','Paperspace')]
        [String]$Provider,

        [Switch]$Force
    )
    begin {
        $commonReqArgs = @{
            Method = 'GET'
            UseBasicParsing = $true
            TimeoutSec = 5
            ErrorAction = 'SilentlyContinue'
        }

        $providerMetadataReq = @{
            'AWS' = @{
                Uri = 'http://169.254.169.254/latest/meta-data'
            }
            'Azure' = @{
                Uri = 'http://169.254.169.254/metadata/instance?api-version=2018-10-01'
                Header = @{ 'Metadata' = 'true' }
            }
            'GCP' = @{
                Uri = 'http://metadata.google.internal/computeMetadata/v1'
                Header = @{ 'metadata-flavor' = 'Google' }
            }
            'Paperspace' = @{
                Uri = 'http://metadata.paperspace.com/meta-data/machine'
            }
        }

        If($global:cloudProviderResult -isnot [Hashtable]) {
            $global:cloudProviderResult = @{}
        }
    }
    process {
        If($Force -or $Provider -notin ${global:cloudProviderResult}.Keys) {
            $reqArgs = $providerMetadataReq.$Provider
            $resp = try { Invoke-WebRequest @commonReqArgs @reqArgs } catch {}
            $global:cloudProviderResult.$Provider = $reqStatus.StatusCode -eq 200
        }
        Write-Output $global:cloudProviderResult.$Provider
    }
    end {}
}

Function Get-CloudProvider {
    [CmdletBinding()]
    param([Switch]$Force)
    $providerSet = (Get-Command -Name 'Test-CloudProvider').Parameters.Provider.Attributes.ValidValues
    $result = $providerSet | Where-Object { Test-CloudProvider -Provider $_ @PSBoundParameters }
    if($result) {
        return $result
    } Else {
        return 'Other'
    }
}

Function Get-SupportedGpu {
    [CmdletBinding()]
    param()

    $supportedGpus = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'Data\SupportedGpuInfo.psd1')

    $cimInstArgs = @{
        ClassName = 'Win32_PnPEntity'
        Filter = "PNPClass = `"Display`" or Name = `"3D Video Controller`""
    }
    $detectedGpus = Get-CimInstance @cimInstArgs

    $foundGpu = @()
    ForEach($gpu in $detectedGpus) {
        If($gpu -match 'PCI\\VEN_(.{4})&DEV_(.{4})') {
            $vendor = $matches[1]
            $device = $matches[2]
            If($supportedGpus.$vendor.$device) {
                $supportedGpus.$vendor.$device.Vendor = $vendor
                $supportedGpus.$vendor.$device.Device = $device
                $foundGpu = New-Object -Type PSObject -Property $supportedGpus.$vendor.$device
            }
        }
    }

    If ($foundGpu.Count -eq 0) {
        Write-Warning 'No supported GPUs found'
    } ElseIf ($foundGpu.Count -gt 1) {
        Write-Warning 'Multiple GPUs found - this configuration only supports 1 GPU'
    } Else {
        return $foundGpu
    }
}

Function Get-GpuDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('AWS','Azure','GCP','Paperspace','Other')]
        [String]$Provider,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Vendor,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Device
    )

    $gpuInfoLookup = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'Data\SupportedGpuInfo.psd1')
    $gpuDriverLookup = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'Data\SupportedGpuDrivers.psd1')

    $gpuInfo = $gpuInfoLookup.$Vendor.$Device
    $driverKey = $gpuDriverLookup.$Provider.$Vendor.$Device

    switch ($driverKey) {
        'Azure' {
            # https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/hpccompute-gpu-windows
            Write-Warning 'Azure VMs should use the NVIDIA GPU Driver Extension for Windows'
        }
        'AWS' {
            $api = 'https://ec2-windows-nvidia-drivers.s3.amazonaws.com'
            $xml = [Xml](Invoke-WebRequest -UseBasicParsing -Uri $api).Content
            $driverList = $xml.ListBucketResult.Contents.Key | Sort
            $latestDriverPath = $driverList | ? { $_ -match '^latest.*win10_server2016_server2019_64bit_international\.exe$' }
            $downloadUri = "$api/$latestDriverPath"
            $downloadUri | Out-String | Write-Verbose
            $downloadPath = Join-Path $env:Temp 'GPUDriver.exe'
            # Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $downloadPath
            [System.Net.WebClient]::new().DownloadFile($downloadUri, $downloadPath)
            return $downloadPath
        }
        'AWS-G4' {
            # https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/install-nvidia-driver.html#nvidia-gaming-driver
            $Bucket = "nvidia-gaming"
            $KeyPrefix = "windows/latest"
            $Objects = Get-S3Object -BucketName $Bucket -KeyPrefix $KeyPrefix -Region 'us-east-1'
            ForEach ($Object in $Objects) {
                $LocalFileName = $Object.Key
                If ($LocalFileName -ne '' -and $Object.Size -ne 0) {
                    $LocalFilePath = Join-Path $env:Temp $LocalFileName
                    Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region 'us-east-1'
                    $file = Get-Item $LocalFilePath
                    If($file.Extension -eq '.zip') {
                        $extractionPath = Join-Path $env:Path $file.BaseName
                        $file | Expand-Archive -DestinationPath $extractionPath
                        Remove-Item $file
                        $installer = Get-ChildItem -Path $extractionPath | ? { $_.Extension -eq '.exe' -and $_.Name -like '*win10*' }
                        return $installer.FullName
                    }
                }
            }
        }
        'GCP' {
            $api = 'https://storage.googleapis.com/nvidia-drivers-us-public'
            $xml = [Xml](Invoke-WebRequest -UseBasicParsing -Uri $api).Content
            $driverList = $xml.ListBucketResult.Contents.Key | Sort
            $winDriverList = $driverList | ? { $_ -match '^.*win10_server2016_server2019_64bit_international\.exe$' }
            $orderedWinDriverList = $winDriverList | % { $_.Split('/')[-1] } | Sort
            $latestDriver = $orderedWinDriverList | Select -Last 1
            $latestDriverVersion = $latestDriver.Split('_')[0]
            $latestDriverPath = $winDriverList | ? { $_ -like "*$latestDriver" }
            $downloadUri = "$api/$latestDriverPath"
            $downloadUri | Out-String | Write-Verbose
            $downloadPath = Join-Path $env:Temp 'GPUDriver.exe'
            # Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $downloadPath
            [System.Net.WebClient]::new().DownloadFile($downloadUri, $downloadPath)
            return $downloadPath
        }
        'Nvidia' {
            $osName = (Get-CimInstance -ClassName 'Win32_OperatingSystem').Caption
            switch -regex ($osName) {
                'Windows 10' { $osId = 57 }
                'Server 201[69]' { $osId = 74 }
                default { throw "This is an unsupported OS: $osName" }
            }
            $api = "https://www.nvidia.com/Download/processFind.aspx?psid=$($gpuInfo.PSID)&pfid=$($gpuInfo.PFID)&osid=$osId&lid=1&whql=1&lang=en-us&ctk=0"
            $html = Invoke-WebRequest -UseBasicParsing -Uri $api
            $rowMatches = $html.Content | select-string -AllMatches '(?smi)<tr id="driverList">(.+?)</tr>' | Select -ExpandProperty 'Matches'
            $driverInfo = @()
            ForEach($row in $rowMatches) {
                $cellMatches = $row.Value | Select-String -AllMatches '(?smi)<td class="gridItem.*?".*?>(.+?)</td>' | select -ExpandProperty Matches
                $cellDriver = $cellMatches[1].Value
                $cellDriver -match "<td class=`"gridItem driverName`">.*?<a href='(.+?)'>(.+?)</a>" | Out-Null
                $driverProp = @{}
                $driverProp.Name = $matches[2]
                $driverProp.Download = 'https:' + $matches[1]
                $cellVersion = $cellMatches[2].Value
                $cellVersion -match '<td class="gridItem">(.+?)</td>' | Out-Null
                $driverProp.Version = $matches[1]
                $driverInfo += New-Object -TypeName PSObject -Property $driverProp
            }
            $downloadPageUri = $driverInfo | Sort Version | Select -Last 1 | Select -ExpandProperty Download
            $downloadPageUri | Out-String | Write-Verbose
            $downloadPage = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUri
            $downloadHref = $downloadPage.Links.href | ? { $_ -match 'DriverDownload' }
            $downloadUri = 'http://us.download.nvidia.com' + $downloadHref.split('=')[1].split('&')[0]
            $downloadPath = Join-Path $env:Temp 'GPUDriver.exe'
            # Invoke-WebRequest -UseBasicParsing -Uri $downloadUri -OutFile $downloadPath
            [System.Net.WebClient]::new().DownloadFile($downloadUri, $downloadPath)
            return $downloadPath
        }
        default {
            Write-Warning "Driver support unknown for $($gpuInfo.Name) on $Provider"
        }
    }
}