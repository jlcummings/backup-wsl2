<#
.SYNOPSIS
This script performs a backup of a particular WSL2 distribution to a tar archive on the host system.
.DESCRIPTION
The script performs a backup using the WSL command of a given distribution.

Note: output redirection can be used to get a more informative output by exposing the log messages when appending '6>&1' 
to the end of script invocation whether arguments are specified or not
.EXAMPLE
.\WSL2-Backup.ps1 -distribution Ubuntu -destination $env:USERPROFILE\backups
.EXAMPLE
.\WSL2-Backup.ps1 -distribution Ubuntu
#>
param(
    [parameter(Mandatory = $true)][string]$destination,
    [ValidateNotNullOrEmpty()][string]$distribution = 'Ubuntu'
)

# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"

# try to create the last segment of the path when the final segment does not exist but the parent does
if (!(Test-Path $destination)) {
    Log "Specified destination directory did not exist, attempting to create it."
    New-Item ($destination) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
}

$command = (Get-Command wsl).Definition
# the backup command
$dateExecuted = $(Get-Date -Format FileDate)
$commandArgs = "--export $distribution $destination\$distribution-$dateExecuted.tar"
# execute the backup
Log "Export of $distribution from WSL2 to a tar file saved in $destination starting"
Invoke-Expression "& $command $commandArgs"
Log "Export of $distribution from WSL2 to a tar file saved in $destination complete"
