# wsl2-backup

## Overview
This set of scripts, not a module, provides the user with a rough, but runnable, method to automatically create a scheduled task to periodically run the `wsl --export ...` command in order to snapshot or archive a WSL2 distribution to a fixed location. 

## Caveats
1.  A lot of cleanup is warranted as it is admittedly very rough; a very first pass, work in progress situation.
2.  The attached restart of docker is a kludge.  For some reason when the `wsl --export ...` command is run, the docker socket or some other component in the chain becomes unasable in the running state and requiers a restart.  Restarting the docker suite is not hard, but it can be time consuming and is sensative to the order and timing of restart so that is why the gnarly scheduled task that triggers on completion of the export is attached during the task registration process.
3.  This is my first powershell project.  I know that I don't know.  Be gentle.
4.  Requires an elevated (aka: administrator) powershell prompt.  The `wsl --export ...` command does not itself require it, but restarting docker does, and the registration of the scheduled task that requires those privileges will check during registration for adequate permission (or am I misremembering?).

## Running

### Pre-requisites
1. Powershell (probably a fairly recent version)
2. Docker Desktop (so by extension, probably a fairly recent version of Windows 10)
3. Access to the administrative, elevated terminal.
4. A copy of these scripts (https://github.com/jlcummings/wsl2-backup)
5. A little powershell knowledge when my default configuration by convention (aka hardcoded nonesence) blows up on you.  Sorry, truth.

### Register the scheduled tasks

From the script directory:
- `.\Register-WSL2-Backup.ps1`

#### Notes

- The default convention is to configure the `wsl --export ...` as the current user who runs the above script (eg: `$env:USERDOMAIN\$env:USERNAME`); however, given enough permissions, it can be configured to run as any other user.  
- The default convention is to configure the location of the resulting backups from the `wsl --export ...` command to a subdirectory of the current user who ran the script (eg: `$env:USERPROFILE\backup`)

### Verify the registered tasks

From the script directory:
- `.\Get-Scheduled-WSL2-Backups.ps1`

### Unregister the scheduled tasks

From the script directory:
- `.\Unregister-WSL2-Backup.ps1`

### Run the backup script

From the script directory:
- `.\WSL2-Backup.ps1`

### Restart the docker suite

From the script directory:
- `.\Restart-Docker.ps1`
