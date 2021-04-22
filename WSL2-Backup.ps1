<#
.SYNOPSIS
This script performs a backup of a particular WSL2 distribution to a tar archive on the host system.
.DESCRIPTION
The script performs a backup using the WSL command of a given distribution.
.EXAMPLE
.\WSLBackup.ps1 -distribution Ubuntu -destination $env:USERPROFILE\backups
.EXAMPLE
.\WSLBackup.ps1 -distribution Ubuntu
#>
param(
    [parameter(Mandatory = $true)][string]$destination,
    [ValidateNotNullOrEmpty()][string]$distribution = 'Ubuntu',
    [string]$dateFormatString = 'yyyyMMdd-hhmmss'
)

# try to create the last segment of the path when the final segment does not exist but the parent does
if (!(Test-Path $destination)) {
    New-Item ($destination) -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
}

$command = (Get-Command wsl).Definition
# the backup command
$dateExecuted = $((Get-Date).ToString($dateFormatString))
$commandArgs = "--export $distribution $destination\$distribution-$dateExecuted.tar"
# execute the backup
Invoke-Expression "& $command $commandArgs"
