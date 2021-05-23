<#

.SYNOPSIS 
The script gets all scheduled WSL2 maintenance tasks the current user
has permission to view that match the given distribution.

.DESCRIPTION 
The script gets all scheduled WSL2 tasks the current user
has permission to view that match the given distribution. By default it matches
all WSL2 tasks that contain 'WSL2' and all 'Restart Docker'
tasks.

.EXAMPLE 
# list all WSL2 tasks that are targeting any distribution registered to the 
# executing user
PS> .\Get-Scheduled-WSL2.ps1
.EXAMPLE
# list any task that is targeting only the distribution called 'Ubuntu'
PS> .\Get-Scheduled-WSL2.ps1 -Distribution Ubuntu

#>
param (
    # name of the distribution to limit the backup task list; by default the wildcard character to allow for all distributions to be returned
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string]
    $Distribution = '*'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

Log "Getting a list of scheduled tasks that match $backupTaskName and 'Restart Docker'"

$backupTaskName = "WSL2 $Distribution backup"
Get-ScheduledTask -TaskName $backupTaskName

$restartDockerTaskName = 'Restart Docker'
Get-ScheduledTask -TaskName $restartDockerTaskName

Log "Scheduled tasks that match '$backupTaskName' and 'Restart Docker' listed above"
