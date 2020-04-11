[DSCLocalConfigurationManager()]
Configuration ParsecHostLcm
{
    Node 'localhost'
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            ConfigurationModeFrequencyMins = '60'
            RebootNodeIfNeeded = $false
            RefreshMode = 'Push'
        }
    }
}
