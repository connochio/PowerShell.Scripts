# Get logon events for a partiular user
Get-WinEvent -ProviderName 'Microsoft-Windows-Security-Auditing' -FilterXPath "*[System[EventID=4624] and EventData[Data[@Name='TargetUserName']='$username']]"

# Get Teradici session start events
Get-WinEvent -ProviderName 'PCoIPAgentService' -FilterXPath "*[System[EventID=88]]"

# Get Teradici session stop events
Get-WinEvent -ProviderName 'PCoIPAgentService' -FilterXPath "*[System[EventID=106]]"
