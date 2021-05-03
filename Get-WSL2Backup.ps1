<#

.SYNOPSIS 
The script gets all scheduled WSL2 backup tasks the current user
has permission to view that match the given distribution.

.DESCRIPTION 
The script gets all scheduled WSL2 backup tasks the current user
has permission to view that match the given distribution. By default it matches
all WSL2 backup tasks that contain 'WSL2 Backup of *' and all 'Restart Docker'
tasks.

.EXAMPLE 
# list all task that are targeting any distribution (default distribution is '*' 
# to get all WSL2 distributions registered to the executing user)
PS> .\Get-WSL2Backup.ps1 -Distribution *
.EXAMPLE
# list any task that is targeting only the distribution called 'Ubuntu'
PS> .\Get-WSL2Backup.ps1 -Distribution Ubuntu

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
