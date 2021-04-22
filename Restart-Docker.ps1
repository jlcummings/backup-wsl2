# Gently messaged via [Restart docker Windows 10 command line](https://stackoverflow.com/a/57560043/549306)
[CmdletBinding()]
param (
    # Service to restart
    [Parameter()]
    [string]
    $serviceIdentifier = "docker",
    # The timestamp format used for output messages
    [Parameter()]
    [string]
    $timestampFormat = "HH:mm:ss",
    # Period of time as a string to wait before timeout should occur +/- roughly 250ms between each check
    [Parameter()]
    [string]
    $timeoutPeriod = "00:00:30"
)
$stoppedStatus = [System.ServiceProcess.ServiceControllerStatus]::Stopped
$runningStatus = [System.ServiceProcess.ServiceControllerStatus]::Running

Write-Output "$((Get-Date).ToString($timestampFormat)) - Restarting $serviceIdentifier"

# note: 'com.docker.*' may not be stopped due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Get-Service | 
Where-Object { $_.name -ilike "*$serviceIdentifier*" -and $_.Status -ieq $runningStatus } | 
Stop-Service -ErrorAction Continue -Confirm:$false -Force  -PassThru | 
Select-Object { $_.WaitForStatus($stoppedStatus, $timeoutPeriod) }

# use wait-process (for longer process exits); if a docker process is still shutting down during the restart of services, you will be left 
# with a miscommunicating docker setup, so all processes must be stopped before a clean restart can occur
Get-Process |
Where-Object { $_.Name -ilike "*$serviceIdentifier*" } | 
Stop-Process -ErrorAction Continue -Confirm:$false -Force -PassThru | 
Wait-Process

# # note: 'com.docker.*' may not be started due to a default lack of permissions and summarily throw a timeout error; elevated permissions are likely required
Get-Service | 
Where-Object { $_.name -ilike "*$serviceIdentifier*" -and $_.Status -ieq $stoppedStatus } | 
Start-Service -PassThru | 
Select-Object { $_.WaitForStatus($runningStatus, $timeoutPeriod) }



# get the path to 'docker' because 'docker desktop' is not registered as an installed application or in a 
# searchable %PATH, but 'docker' is and 'Docker Desktop.exe' seems to be installed relative to '..\..\docker.exe' 
$dockerDesktopPath = (Get-Item ((Get-Command -Name $serviceIdentifier).Definition)).Directory.Parent.Parent.FullName | Join-Path -ChildPath "Docker Desktop.exe"

Write-Output "$((Get-Date).ToString($timestampFormat)) - Starting Docker Desktop"
# call/invoke the application
& $dockerDesktopPath

$dd = Get-Process "Docker Desktop"
$startTimeout = [DateTime]::Now.AddSeconds(90)
$timeoutHit = $true

while ($dd.WaitForInputIdle(10000) -and (Get-Date) -le $startTimeout) {

    Start-Sleep -Seconds 15
    $ErrorActionPreference = 'Continue'
    try {
        $info = ("$serviceIdentifier info")
        Write-Verbose "$((Get-Date).ToString($timestampFormat)) - `t$serviceIdentifier info executed. Is Error?: $($info -ilike "*error*"). Result was: $info"

        if ($info -ilike "*error*") {
            Write-Verbose "$((Get-Date).ToString($timestampFormat)) - `t$serviceIdentifier info had an error. throwing..."
            throw "Error running info command $info"
        }
        $timeoutHit = $false
        break
    }
    catch {

        if (($_ -ilike "*error during connect*") -or ($_ -ilike "*errors pretty printing info*") -or ($_ -ilike "*Error running info command*")) {
            Write-Output "$((Get-Date).ToString($timestampFormat)) -`t Docker Desktop startup not yet completed, waiting and checking again"
        }
        else {
            Write-Output "Unexpected Error: `n $_"
            return
        }
    }
    $ErrorActionPreference = 'Stop'
}
if ($timeoutHit -eq $true) {
    throw "Timeout hit waiting for docker to startup"
}

Write-Output "$((Get-Date).ToString($timestampFormat)) - Docker restarted"