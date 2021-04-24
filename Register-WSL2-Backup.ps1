<#
.SYNOPSIS
This script registers a scheduled task to perform a backup of a particular WSL2 distribution.
.DESCRIPTION
This script registers a scheduled task to perform a backup of a particular WSL2 distribution.
.EXAMPLE
.\RegisterWSLBackup.ps1 -startIn D:\backups\wsl -distribution Ubuntu -scheduledTime 2:30am -timeLimit (New-TimeSpan -Hours 4) -executor powershell
.EXAMPLE
.\RegisterWSLBackup.ps1 -distribution Ubuntu
#>

param(
    [ValidateNotNullOrEmpty()][string]$user = "$env:USERDOMAIN\$env:USERNAME",
    [ValidateNotNullOrEmpty()][string]$destination = "$env:USERPROFILE\backup",
    [ValidateNotNullOrEmpty()][string]$distribution = 'Ubuntu',
    [ValidateNotNullOrEmpty()][string]$scheduledTime = "1am",
    [ValidateNotNullOrEmpty()][System.DayOfWeek]$dayOfWeek = 'Sunday',
    [ValidateNotNullOrEmpty()][timespan]$timeLimit = (New-TimeSpan -Hours 6),
    [ValidateNotNullOrEmpty()][string]$executor = 'powershell',
    [ValidateNotNullOrEmpty()][string]$taskNameFormatString = "{0} {1} backup",
    [ValidateNotNullOrEmpty()][string]$taskDescriptionFormatString = "{0} archived at or about {1}",
    [string]$taskNamePrefix = "WSL2",
    [string]$taskFolder = "Custom Maintenance"
)
$sanitizedUser = [regex]::Escape($user)
$sanitizedDestination = [regex]::Escape($destination)


$taskName = $taskNameFormatString -f $taskNamePrefix, $distribution
$taskDescription = $taskDescriptionFormatString -f $taskName, $scheduledTime

$command = "-NoProfile -file $PSScriptRoot\WSL2-Backup.ps1 -distribution $distribution -destination $sanitizedDestination"
$cmdExecutor = (Get-Command $executor).Definition


$principle = New-ScheduledTaskPrincipal -UserId $sanitizedUser -LogonType  ServiceAccount
$action = New-ScheduledTaskAction -Execute $cmdExecutor -Argument $command -WorkingDirectory $sanitizedDestination
$settingsSet = New-ScheduledTaskSettingsSet -ExecutionTimeLimit $timeLimit -WakeToRun -StartWhenAvailable
$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $dayOfWeek -At $scheduledTime

Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath $taskFolder -TaskName $taskName -Description $taskDescription -Principal $principle -Settings $settingsSet

$dockerRestartCommand = "-NoProfile -file $PSScriptRoot\Restart-Docker.ps1"
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
            *[EventData[@Name="ActionSuccess"][Data[@Name="TaskName"]="\$taskFolder\$taskName"][Data[@Name="ResultCode"]="0"]]
        </Select>
    </Query>
</QueryList>
"@
$dockerRestartTrigger.Subscription = $subscription

Register-ScheduledTask -Action $dockerRestartAction -Trigger $dockerRestartTrigger -TaskPath $taskFolder -TaskName "Restart Docker" -Description "Restart Docker on completion of '$taskName'" -Principal $dockerRestartPrinciple -Settings $dockerRestartSettings