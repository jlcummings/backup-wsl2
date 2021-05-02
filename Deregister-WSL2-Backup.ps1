<#
.SYNOPSIS
The script deregisters a WSL backup a scheduled task for a given distribution. 
.DESCRIPTION
The script deregisters a WSL backup a scheduled task for a given distribution.  The default 
distribution is "Ubuntu".
The naming convention for the script follows the spelling suggestion correction for 'unregister'. 
However, the powershell module that actually performs the removal of the tasks either follows a
different dictionary, or ignores suggested spelling for that activity.

Note: output redirection can be used to get a more informative output by exposing the log messages when appending '6>&1' 
to the end of script invocation whether arguments are specified or not

.EXAMPLE
# remove a task that is targetting a default distribution called 'Ubuntu'
.\Deregister-WSL2-Backup.ps1
.EXAMPLE
.\Deregister-WSL2-Backup.ps1 -distribution fedora
#>

param(
    [ValidateNotNullOrEmpty()]
    [string]$distribution = 'Ubuntu'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"


$taskName = "WSL2 $distribution backup"

try {
    Log "Unregistering scheduled task $taskName"
    Unregister-ScheduledTask -TaskName $taskName
    Log "Scheduled task $taskName unregistered"
}
catch {
    Log "Unable to remove any tasks named $taskName" -LogLevel Warning
}

try {
    Log "Unregistering scheduled task 'Restart Docker'"
    Unregister-ScheduledTask -TaskName 'Restart Docker'
    Log "Scheduled task 'Restart Docker' unregistered"
}
catch {
    Log "Unable to remove any tasks named 'Restart Docker'" -LogLevel Warning
}