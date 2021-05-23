<# 

.SYNOPSIS 
The script unregisters a scheduled backup of a WSL2 distribution. 

.DESCRIPTION 
The script unregisters a scheduled backup of a WSL2 distribution. 

.NOTES
Usage

The default distribution is 'Ubuntu'. 

Style

The naming convention for the script does not follow the spelling correction
suggestion for 'unregister' which should be deregister. The correct opposing
analogue to register is deregister. However, the powershell
[approved verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.1)
includes unregister and not deregister.

.EXAMPLE
# remove a scheduled backup that is targetting the default distribution
PS> .\Unregister-ScheduledBackup-WSL2.ps1

.EXAMPLE
# remove a scheduled backup that is targetting the fedora distribution
PS> .\Unregister-ScheduledBackup-WSL2.ps1 -Distribution fedora

#>

param(
    # Name of the WSL2 distribution to backup as listed in the `wsl -l` command output
    [ValidateNotNullOrEmpty()]
    [string]$Distribution = 'Ubuntu'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"


$taskName = "WSL2 $Distribution backup"

try {
    Log "Unregistering $taskName"
    Unregister-ScheduledTask -TaskName $taskName
    Log "$taskName unregistered"
}
catch {
    Log "Unable to remove $taskName because of error: $_" -LogLevel Warning
}

try {
    Log 'Unregistering triggered task ''Restart Docker'''
    Unregister-ScheduledTask -TaskName 'Restart Docker'
    Log 'Triggered task ''Restart Docker'' unregistered'
}
catch {
    Log "Unable to remove 'Restart Docker' because of error: $_" -LogLevel Warning
}