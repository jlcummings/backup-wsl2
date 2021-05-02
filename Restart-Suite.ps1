<#
.SYNOPSIS
This script restarts an application suite 
.DESCRIPTION
This script restarts an application suite and by convention, docker is the suite the script was first designed and is targeted to.
Gently messaged via [Restart docker Windows 10 command line](https://stackoverflow.com/a/57560043/549306)

Note: output redirection can be used to get a more informative output by exposing the log messages when appending '6>&1' 
to the end of script invocation whether arguments are specified or not
.EXAMPLE
.\Restart-Suite.ps1 -serviceTimeout 00:00:15
#>
param (
    # Period of time to wait before timeout should occur +/- roughly 250ms between each check
    [string]$serviceTimeout = '00:00:30',
    # Service identifier; a string to match against the list of system services
    [string]$serviceIdentifier = 'docker',
    # Service health check command
    [string]$serviceHealthCommand = 'docker info',
    # Client application name; note: omit including 'exe' as that will be appended within the script
    [string]$clientAppName = 'Docker Desktop',
    # host path to the client application; note: targeting path to 'docker' because 'docker desktop' is not
    # registered as an installed application or in a searchable %PATH, but 'docker' is and 'Docker Desktop.exe' 
    # seems to currently be installed relative to '..\..\docker.exe'; if the client app location is not valid, 
    # it will not be prepended to the client app name when attempting to restart the client app
    [string]$clientAppLocation = (Get-Item ((Get-Command -Name $serviceIdentifier).Definition)).Directory.Parent.Parent.FullName,
    # a regular expression pattern that matches a variety of messages received when using the service health command while the service is still starting and not ready
    [string]$serviceStartupHealthMessagePattern = "error during connect|Error response from daemon"
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

$clientAppPath = ''
if (Test-Path $clientAppLocation) {
    $clientAppPath = $clientAppLocation | Join-Path -ChildPath "$clientAppName.exe"
}
else {
    $clientAppPath = "$clientAppName.exe"
}

$stopped = [System.ServiceProcess.ServiceControllerStatus]::Stopped
$running = [System.ServiceProcess.ServiceControllerStatus]::Running

Log "Restarting $serviceIdentifier"

# note: some services may not be stopped due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Log "Stopping all services that match *$serviceIdentifier*"
Get-Service -Name "*$serviceIdentifier*" | 
Where-Object Status -ieq $running | 
ForEach-Object {
    Log "`tStopping service $($_.ServiceName)..."
    Stop-Service -InputObject $_ -ErrorAction Continue -Confirm:$false -Force
    $_.Refresh()
    $_.WaitForStatus($stopped, $serviceTimeout)
    $_.Refresh()
    Log "`tService $($_.ServiceName) is $($_.Status)"
}
Log "All services that match *$serviceIdentifier* should be stopped"

# use wait-process (for longer process exits); if a dependant process is still shutting down during the restart of services, you will be left 
# with a miscommunicating setup, so all processes must be stopped before a clean restart can occur
Log "Stopping all processes that match *$clientAppName*"
Get-Process -Name "*$clientAppName*" |
ForEach-Object {
    Log "`t$($_.Name) with id of $($_.Id) will be stopped..."
    Stop-Process -InputObject $_
    Out-Null $_.WaitForExit(1000)
    Log "`tProcess $($_.Name) with id of $($_.Id) is stopped."
}
Log "All processes that match *$clientAppName* should have exited"

# note: some sevices may not be started due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Log "Starting all services that match *$serviceIdentifier*"
Get-Service -Name "*$serviceIdentifier*" | 
Where-Object Status -ieq $stopped | 
ForEach-Object {
    Log "`tStarting service $($_.ServiceName)..."
    $_.Start()
    $_.Refresh()
    $_.WaitForStatus($running, $serviceTimeout)
    $_.Refresh()
    Log "`tService $($_.ServiceName) is $($_.Status)"
}
Log "All services that match *$serviceIdentifier* should be started"


Log "Starting $clientAppName"
# call/invoke the application
Start-Process -FilePath $clientAppPath -PassThru |
ForEach-Object {
    $_.Refresh()
    do {
        if ($_.HasExited -eq $true) {
            break;
        }
    } while ($_.WaitForInputIdle(1000) -ne $true)
}
Log "$clientAppName launched, but likely waiting for background services to finish starting up before it is fully ready"

$startTimeout = [DateTime]::Now.AddSeconds(90)
$timeoutHit = $true
    
while ((Get-Date) -le $startTimeout) {
    
    Start-Sleep -Seconds 15
    $ErrorActionPreference = 'Continue'
    try {
        $healthCheckResult = $($serviceHealthCommand)
        Log "`tHealth command: $serviceHealthCommand executed."
    
        if ($healthCheckResult -ilike '*error*') {
            Log "`tHealth command: $serviceHealthCommand had an error, but possibly not unexpected as services continue to finish starting; throwing..."
            throw "Error running '$serviceHealthCommand': $healthCheckResult"
        }
        Log "`tHealth command: $serviceHealthCommand did not result in error, so presumably health and ready to use."
        $timeoutHit = $false
        break
    }
    catch {
    
        if ($_ | Where-Object { $_ -match $serviceStartupHealthMessagePattern } | ForEach-Object { $Matches.Count -ge 1 }) {
            Log "`tService $serviceIdentifier startup not yet completed, waiting and checking again"
        }
        else {
            Log "Unexpected Error: `n $_" -LogLevel Error
            throw "Unexpected Error: $_"
        }
    }
    $ErrorActionPreference = 'Stop'
}
if ($timeoutHit -eq $true) {
    throw "Timeout waiting for $serviceIdentifier to complete startup"
}

Log "$serviceIdentifier restarted"    
