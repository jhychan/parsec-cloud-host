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
            $global:cloudProviderResult.$Provider = $resp.StatusCode -eq 200
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
