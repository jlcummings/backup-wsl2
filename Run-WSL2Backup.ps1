<#

.SYNOPSIS
This script performs a backup of a WSL2 distribution to a tar archive on the host system.

.DESCRIPTION
This script performs a backup of a WSL2 distribution to a tar archive on the host system.

.EXAMPLE
PS> .\Run-WSL2Backup.ps1 -Distribution Ubuntu -DestinationPath $env:USERPROFILE\backups

.EXAMPLE
PS> .\Run-WSL2Backup.ps1 -Distribution Ubuntu

#>
param(
    # path to save the archived, snapshot
    [parameter(Mandatory = $true)][string]$DestinationPath,
    # name of the WSL2 distribution as listed in the output of `wsl -l`
    [ValidateNotNullOrEmpty()][string]$Distribution = 'Ubuntu'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

# try to create the path when it does not exist
if (!(Test-Path $DestinationPath)) {
    Log 'Specified DestinationPath directory did not exist, attempting to create it.'
    New-Item ($DestinationPath) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
}

$command = (Get-Command wsl).Definition
# the backup command
$dateExecuted = $(Get-Date -Format FileDate)
$commandArgs = "--export $Distribution $DestinationPath\$Distribution-$dateExecuted.tar"
# execute the backup
Log "Export of $Distribution from WSL2 to a tar file saved in $DestinationPath starting"
Invoke-Expression "& $command $commandArgs"
Log "Export of $Distribution from WSL2 to a tar file saved in $DestinationPath complete"
