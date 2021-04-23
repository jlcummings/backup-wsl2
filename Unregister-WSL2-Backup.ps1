<#
.SYNOPSIS
The script unregisters a scheduled task to perform a WSL backup with the Windows Task Scheduler. 
.DESCRIPTION
The script unregisters a scheduled task to perform a WSL backup with the Windows Task Scheduler. 
.EXAMPLE
# remove a task that is targetting a default distribution called 'Ubuntu'
.\UnregisterWSLBackup.ps1
.EXAMPLE
.\UnregisterWSLBackup.ps1 -distribution fedora
#>

param(
    [ValidateNotNullOrEmpty()][string]$distribution = 'Ubuntu',
    [string]$taskNamePrefix = "WSL2",
    [ValidateNotNullOrEmpty()][string]$taskNameFormatString = "{0} {1} backup"

)


$taskName = $taskNameFormatString -f $taskNamePrefix, $distribution

try {
    Unregister-ScheduledTask -TaskName $taskName
}
catch {
    Write-Output "Unable to remove any tasks named $taskName"
}

try {
    Unregister-ScheduledTask -TaskName "Restart Docker"
}
catch {
    Write-Output "Unable to remove any tasks named Restart Docker"
}