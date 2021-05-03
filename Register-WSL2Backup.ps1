<#
.SYNOPSIS
This script registers a scheduled backup of a WSL2 distribution.
.DESCRIPTION
This script registers a scheduled backup of a WSL2 distribution.
.EXAMPLE
.\Register-WSL2Backup.ps1 -DestinationPath D:\backups\wsl -Distribution Ubuntu -DayOfWeek Tuesday -Time 2:30am -TimeLimit (New-TimeSpan -Hours 4)
.EXAMPLE
.\Register-WSL2Backup.ps1 -Distribution Ubuntu
#>

param(
    [ValidateNotNullOrEmpty()][string]$User = "$env:USERDOMAIN\$env:USERNAME",
    [ValidateNotNullOrEmpty()][string]$DestinationPath = "$env:USERPROFILE\backup",
    [ValidateNotNullOrEmpty()][string]$Distribution = 'Ubuntu',
    [ValidateNotNullOrEmpty()][string]$Time = '1am',
    [ValidateNotNullOrEmpty()][System.DayOfWeek]$DayOfWeek = 'Sunday',
    [ValidateNotNullOrEmpty()][timespan]$TimeLimit = (New-TimeSpan -Hours 6),
    [string]$TaskPath = 'Custom Maintenance'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

Log "Starting to configure"
$sanitizedUser = [regex]::Escape($User)
$sanitizedDestination = [regex]::Escape($DestinationPath)

$taskName = "WSL2 $Distribution backup"
$taskDescription = "$taskName archived at or about $Time"

$command = "-NoProfile -file $PSScriptRoot\Run-WSL2Backup.ps1 -Distribution $Distribution -DestinationPath $sanitizedDestination"
$cmdExecutor = (Get-Command 'powershell').Definition
Log "Done configuring"

Log "Constructing new scheduled task parameters for $Distribution backup"
$principle = New-ScheduledTaskPrincipal -UserId $sanitizedUser -LogonType  ServiceAccount
$action = New-ScheduledTaskAction -Execute $cmdExecutor -Argument $command -WorkingDirectory $sanitizedDestination
$settingsSet = New-ScheduledTaskSettingsSet -ExecutionTimeLimit $TimeLimit -WakeToRun -StartWhenAvailable
$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $DayOfWeek -At $Time
Log "New scheduled task parameters for the backup constructed"

Log "Registering the new scheduled task to perform the backup"
Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath $TaskPath -TaskName $taskName -Description $taskDescription -Principal $principle -Settings $settingsSet
Log "The scheduled task to perform the backup is registered"

Log "Constructing new scheduled task parameters for the restart of docker"
$dockerRestartCommand = "-NoProfile -file $PSScriptRoot\Restart-Suite.ps1"
$dockerRestartPrinciple = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
$dockerRestartAction = New-ScheduledTaskAction -Execute $cmdExecutor -Argument $dockerRestartCommand
$dockerRestartSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -WakeToRun -StartWhenAvailable
$taskEventTrigger = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$dockerRestartTrigger = New-CimInstance -CimClass $taskEventTrigger -ClientOnly
$dockerRestartTrigger.Enabled = $true
# xpath query against the logs; see https://docs.microsoft.com/en-us/archive/blogs/davethompson/running-a-scheduled-task-after-another
#             *[System/EventID=102[EventData[Data[@Name='ResultCode']=0][Data[@Name='TaskName']='\my-task']]

$subscription = @"
<QueryList>
    <Query Id="0" Path="Microsoft-Windows-TaskScheduler/Operational">
        <Select Path="Microsoft-Windows-TaskScheduler/Operational">
            *[EventData[@Name="ActionSuccess"][Data[@Name="TaskName"]="\$TaskPath\$taskName"][Data[@Name="ResultCode"]="0"]]
        </Select>
    </Query>
</QueryList>
"@
$dockerRestartTrigger.Subscription = $subscription
Log "New scheduled task parameters for docker restart constructed"

Log "Registering the new scheduled task to perform a docker restart"
Register-ScheduledTask -Action $dockerRestartAction -Trigger $dockerRestartTrigger -TaskPath $TaskPath -TaskName 'Restart Docker' -Description "Restart Docker on completion of '$taskName'" -Principal $dockerRestartPrinciple -Settings $dockerRestartSettings
Log "The scheduled task to perform a docker restart is registered"
