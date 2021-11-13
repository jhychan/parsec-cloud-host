[DSCLocalConfigurationManager()]
Configuration ParsecHostLcm
{
    Node 'localhost'
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration'
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $false
            RefreshMode = 'Push'
        }
    }
}
