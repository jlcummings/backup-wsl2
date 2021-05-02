<#
.SYNOPSIS
The script queries all scheduled tasks the current user has permission to view that match the given distribution. 
.DESCRIPTION
The script queries all scheduled tasks the current user has permission to view that match the given distribution. 
By default it matches all WSL2 backup tasks that contain "WSL2 * backup" and all "Docker" tasks.

Note: output redirection can be used to get a more informative output by exposing the log messages when appending '6>&1' 
to the end of script invocation whether arguments are specified or not
.EXAMPLE
# list all task that are targeting any distribution
.\Get-Scheduled-WSL2-Backups.ps1 -distribution *
# list any task that is targeting only the distribution called 'Ubuntu'
.\Get-Scheduled-WSL2-Backups.ps1 -distribution Ubuntu
#>
param (
    # name of the distribution to limit the backup task list; by default the wildcard character to allow for all distributions to be returned
    [ValidateNotNullOrEmpty()]
    [string]
    $distribution = '*'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

Log "Getting a list of scheduled tasks that match $backupTaskName and *Docker*"

$backupTaskName = "WSL2 $distribution backup"
Get-ScheduledTask -TaskName $backupTaskName

$restartDockerTaskName = '*Docker*'
Get-ScheduledTask -TaskName $restartDockerTaskName

Log "Scheduled tasks that match $backupTaskName and *Docker* listed above"
