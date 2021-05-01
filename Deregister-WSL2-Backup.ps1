<#
.SYNOPSIS
The script deregisters a WSL backup a scheduled task for a given distribution. 
.DESCRIPTION
The script deregisters a WSL backup a scheduled task for a given distribution.  The default 
distribution is "Ubuntu".
The naming convention for the script follows the spelling suggestion correction for 'unregister'. 
However, the powershell module that actually performs the removal of the tasks either follows a
different dictionary, or ignores suggested spelling for that activity.
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


$taskName = "WSL2 $distribution backup"

try {
    Unregister-ScheduledTask -TaskName $taskName
}
catch {
    Write-Output "Unable to remove any tasks named $taskName"
}

try {
    Unregister-ScheduledTask -TaskName 'Restart Docker'
}
catch {
    Write-Output 'Unable to remove any tasks named Restart Docker'
}