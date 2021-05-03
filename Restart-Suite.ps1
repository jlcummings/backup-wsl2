<#

.SYNOPSIS
This script restarts an application suite 

.DESCRIPTION
This script restarts an application suite and by convention docker is the suite the script was first designed and is targeted to.
Gently messaged via [Restart docker Windows 10 command line](https://stackoverflow.com/a/57560043/549306)

.EXAMPLE
.\Restart-Suite.ps1 -ServiceTimeout 00:00:15

#>
param (
    # Period of time to wait before timeout should occur
    [ValidateNotNullOrEmpty()]
    [timespan]$ServiceTimeout = (New-TimeSpan -Seconds 30),
    # String to match against the list of system services
    [ValidateNotNullOrEmpty()]
    [string]$ServiceIdentifier = 'docker',
    # Service health check command
    [string]$ServiceHealthCommand = 'docker info',
    # Regular expression pattern that is used to match a variety of messages received as a result of the service health command while the service is starting and not ready
    [string]$ServiceHealthStartupMessagePattern = "error during connect|Error response from daemon",
    # Client application name; note: quote appropriately if spaces embedded
    [string]$ClientAppName = 'Docker Desktop.exe',
    # Path to the client application parent directory; note: targeting path to 'docker' because 'docker desktop' is not
    # registered as an installed application or in a searchable %PATH, but 'docker' is and 'Docker Desktop.exe' 
    # seems to currently be installed relative to '..\..\docker.exe'; if the client app parent path is not valid, 
    # or the client app name is not set, a client app path will not be set and no client app operations will be performed; 
    # whatever client app is running will continue to run
    [string]$ClientAppParentPath = (Get-Item ((Get-Command -Name $ServiceIdentifier).Definition)).Directory.Parent.Parent.FullName
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

$clientAppPath = ''
if ($ClientAppName && Test-Path $ClientAppParentPath) {
    $clientAppPath = $ClientAppParentPath | Join-Path -ChildPath "$ClientAppName"
}
else {
    Log "No client app tasks will be performed.  Verify client application name and the containing directory path.  Client app: '$ClientAppName'`nClient app containing directory path: '$ClientAppParentPath'" -LogLevel Warning
}

$stopped = [System.ServiceProcess.ServiceControllerStatus]::Stopped
$running = [System.ServiceProcess.ServiceControllerStatus]::Running

Log "Restarting $ServiceIdentifier"

# note: some services may not be stopped due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Log "Stopping all services that match *$ServiceIdentifier*"
Get-Service -Name "*$ServiceIdentifier*" | 
Where-Object Status -ieq $running | 
ForEach-Object {
    Log "`tStopping service $($_.ServiceName)..."
    Stop-Service -InputObject $_ -ErrorAction Continue -Confirm:$false -Force
    $_.Refresh()
    $_.WaitForStatus($stopped, $ServiceTimeout)
    $_.Refresh()
    Log "`tService $($_.ServiceName) is $($_.Status)"
}
Log "All services that match *$ServiceIdentifier* should be stopped"

# don't stop what we can't restart, and if the client app path is not set, we can't start it
if ($clientAppPath) {
    # when a dependant process is still shutting down during the restart of services, you will be left 
    # with a miscommunicating setup, so all processes must be stopped before a clean restart can occur
    Log "Stopping all processes that match *$($ClientAppName | Split-Path -LeafBase)*"
    Get-Process -Name "*$($ClientAppName | Split-Path -LeafBase)*" |
    ForEach-Object {
        Log "`t$($_.Name) with id of $($_.Id) will be stopped..."
        Stop-Process -InputObject $_
        Out-Null $_.WaitForExit(1000)
        Log "`tProcess $($_.Name) with id of $($_.Id) is stopped."
    }
    Log "All processes that match *$($ClientAppName | Split-Path -LeafBase)* should have exited"
}

# note: some sevices may not be started due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Log "Starting all services that match *$ServiceIdentifier*"
Get-Service -Name "*$ServiceIdentifier*" | 
Where-Object Status -ieq $stopped | 
ForEach-Object {
    Log "`tStarting service $($_.ServiceName)..."
    $_.Start()
    $_.Refresh()
    $_.WaitForStatus($running, $ServiceTimeout)
    $_.Refresh()
    Log "`tService $($_.ServiceName) is $($_.Status)"
}
Log "All services that match *$ServiceIdentifier* should be started"

# don't stop what we can't restart, and if the client app path is not set, we can't start it
if ($clientAppPath) {
    Log "Starting $ClientAppName"
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
    Log "$ClientAppName launched, but likely waiting for background services to finish starting up before it is fully ready"

    # when no health command is specified, there is no way to query service health, so skip it
    if ($ServiceHealthCommand) {

        $startTimeout = [DateTime]::Now.AddSeconds(90)
        $timeoutHit = $true
    
        while ((Get-Date) -le $startTimeout) {
    
            Start-Sleep -Seconds 15
            $ErrorActionPreference = 'Continue'
            try {
                $healthCheckResult = $($ServiceHealthCommand)
                Log "`tHealth command: $ServiceHealthCommand executed."
    
                if ($healthCheckResult -ilike '*error*') {
                    Log "`tHealth command: $ServiceHealthCommand had an error, but possibly not unexpected as services continue to finish starting; throwing..."
                    throw "Error running '$ServiceHealthCommand': $healthCheckResult"
                }
                Log "`tHealth command: $ServiceHealthCommand did not result in error, so presumably health and ready to use."
                $timeoutHit = $false
                break
            }
            catch {
    
                if ($_ | Where-Object { $_ -match $ServiceHealthStartupMessagePattern } | ForEach-Object { $Matches.Count -ge 1 }) {
                    Log "`tService $ServiceIdentifier startup not yet completed, waiting and checking again"
                }
                else {
                    Log "Unexpected Error: `n $_" -LogLevel Error
                    throw "Unexpected Error: $_"
                }
            }
            $ErrorActionPreference = 'Stop'
        }
        if ($timeoutHit -eq $true) {
            throw "Timeout waiting for $ServiceIdentifier to complete startup"
        }
    }
}
Log "$ServiceIdentifier restarted"    
