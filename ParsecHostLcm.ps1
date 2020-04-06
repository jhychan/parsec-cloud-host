[DSCLocalConfigurationManager()]
Configuration ParsecHostLcm
{
    Node 'localhost'
    {
        Settings
        {
        	ActionAfterReboot = 'ContinueConfiguration'
        	ConfigurationMode = 'ApplyAndAutoCorrect'
        	ConfigurationModeFrequencyMins = '60'
        	RebootNodeIfNeeded = $false
            RefreshMode = 'Push'
        }
    }
}
