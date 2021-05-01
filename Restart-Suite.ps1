<#
.SYNOPSIS
This script restarts an application suite 
.DESCRIPTION
This script restarts an application suite and by convention, docker is the suite the script was first designed and is targeted to.
Gently messaged via [Restart docker Windows 10 command line](https://stackoverflow.com/a/57560043/549306)
.EXAMPLE
.\Restart-Suite.ps1 -serviceTimeout 00:00:15
#>
param (
    # Period of time to wait before timeout should occur +/- roughly 250ms between each check
    [string]$serviceTimeout = '00:00:30',
    # Service identifier; a string to match against the list of system services
    [string]$serviceIdentifier = 'docker',
    # Service health check command
    [string]$serviceHealthCommand = 'info',
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
$clientAppPath = ''
if (Test-Path $clientAppLocation) {
    $clientAppPath = $clientAppLocation | Join-Path -ChildPath "$clientAppName.exe"
}
else {
    $clientAppPath = "$clientAppName.exe"
}

$timestampFormat = 'HH:mm:ss'
$stopped = [System.ServiceProcess.ServiceControllerStatus]::Stopped
$running = [System.ServiceProcess.ServiceControllerStatus]::Running

Write-Output "$((Get-Date).ToString($timestampFormat)) - Restarting $serviceIdentifier"

# note: some services may not be stopped due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Get-Service -Name "*$serviceIdentifier*" | 
Where-Object Status -ieq $running | 
ForEach-Object {
     Write-Output "Stopping service $($_.ServiceName)..."
     Stop-Service -InputObject $_ -ErrorAction Continue -Confirm:$false -Force
     $_.Refresh()
     $_.WaitForStatus($stopped, $serviceTimeout)
     $_.Refresh()
     Write-Output "Service $($_.ServiceName) is $($_.Status)"
}

# use wait-process (for longer process exits); if a dependant process is still shutting down during the restart of services, you will be left 
# with a miscommunicating setup, so all processes must be stopped before a clean restart can occur
Get-Process -Name "*$clientAppName*" |
ForEach-Object {
    Write-Output "$($_.Name) with id of $($_.Id) will be stopped..."
    Stop-Process -InputObject $_
    Out-Null $_.WaitForExit(1000)
    Write-Output "Process $($_.Name) with id of $($_.Id) is stopped."
}

# note: some sevices may not be started due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Get-Service -Name "*$serviceIdentifier*" | 
Where-Object Status -ieq $stopped | 
ForEach-Object {
    Write-Output "Starting service $($_.ServiceName)..."
    $_.Start()
    $_.Refresh()
    $_.WaitForStatus($running, $serviceTimeout)
    $_.Refresh()
    Write-Output "Service $($_.ServiceName) is $($_.Status)"
}


Write-Output "$((Get-Date).ToString($timestampFormat)) - Starting $clientAppName"
# call/invoke the application
Start-Process -FilePath $clientAppPath -PassThru |
ForEach-Object {
    $_.Refresh()
    do {
        if ($_.HasExited -eq $true)
        {
            break;
        }
    } while ($_.WaitForInputIdle(1000) -ne $true)
    Write-Output "$((Get-Date).ToString($timestampFormat)) - $clientAppName launched, but likely waiting for background services to finish starting up."
}

$startTimeout = [DateTime]::Now.AddSeconds(90)
$timeoutHit = $true
    
while ((Get-Date) -le $startTimeout) {
    
    Start-Sleep -Seconds 15
    $ErrorActionPreference = 'Continue'
    try {
        $healthCheckResult = & $serviceIdentifier $serviceHealthCommand
        Write-Output "$((Get-Date).ToString($timestampFormat)) - `tHealth command: $serviceIdentifier $serviceHealthCommand executed."
    
        if ($healthCheckResult -ilike '*error*') {
            Write-Output "$((Get-Date).ToString($timestampFormat)) - `tHealth command: $serviceIdentifier $serviceHealthCommand had an error, but possibly not unexpected as services continue to finish starting; throwing..."
            throw "Error running '$serviceIdentifier $serviceHealthCommand': $healthCheckResult"
        }
        Write-Output "$((Get-Date).ToString($timestampFormat)) - `tHealth command: $serviceIdentifier $serviceHealthCommand did not result in error, so presumably health and ready to use."
        $timeoutHit = $false
        break
    }
    catch {
    
        if ($_ | Where-Object { $_ -match $serviceStartupHealthMessagePattern } | ForEach-Object { $Matches.Count -ge 1}) {
            Write-Output "$((Get-Date).ToString($timestampFormat)) -`tService $serviceIdentifier startup not yet completed, waiting and checking again"
        }
        else {
            Write-Error "Unexpected Error: `n $_"
            throw "Unexpected Error: $_"
        }
    }
    $ErrorActionPreference = 'Stop'
}
if ($timeoutHit -eq $true) {
    throw "Timeout waiting for $serviceIdentifier to startup"
}

Write-Output "$((Get-Date).ToString($timestampFormat)) - $serviceIdentifier restarted"    
