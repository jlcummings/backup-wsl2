# wsl2-backup

## Overview

This set of [Powershell](https://docs.microsoft.com/en-us/powershell/) scripts provides the user with a rough, but runnable method to create a scheduled task that when periodically, automatically run, creates a snapshot or archive from a WSL2 distribution to a fixed location on the local host system. Under the hood, it uses the `wsl --export ...` command of the host to archive the instance.

## Caveats

1. A lot of cleanup is warranted as it is admittedly very rough; a very first pass, work in progress situation.
2. The attached restart of docker is a kludge. For some reason when the `wsl --export ...` command is run, the docker socket or some other component in the docker desktop suite becomes unusable in the running state and requires a restart. Restarting the docker suite is not hard, but can be time consuming and is sensitive to the order and timing of each component restart. That is why the gnarly scheduled task that triggers on completion of the underlying export is included during the task registration process.
3. This is my first powershell project. I know that I don't know. Be gentle. I appreciate opinions, but may choose not to adopt any or all suggestions.
4. Requires an elevated (aka: administrator) powershell prompt. The underlying `wsl --export ...` command does not itself require elevated privileges, but restarting docker typically does (depending on how it was installed or reconfigured), and the registration of the scheduled task that specifies elevated privileges will require elevated privileges during registration.

## Running

### Pre-requisites

1. Powershell (probably a fairly recent version). v7.1 is the version in use during development (and 'production' for that matter).
2. Expectation of Docker Desktop (so by extension, probably a fairly recent version of Windows 10, and in development 20H2 is the release in use).
3. Access to the administrative, elevated terminal.
4. A complete copy of these scripts (<https://github.com/jlcummings/wsl2-backup>)
5. A little powershell knowledge when my default configuration by convention (aka hardcoded, naive nonsense) blows up on you it can be remedied. Sorry, truth.

## Notes

### Configuration

A few notes on configurable conventions employed within the scripts:

- Internally, `wsl --export ...` is executed as the current user who runs the backup script (eg: `$env:USERDOMAIN\$env:USERNAME`); however, given enough permissions, the backup can be configured to run as any other user. This is specified adding the `-User ...` option of the registration script: `.\Register-WSL2Backup.ps1 -User computer-alpha\tom`
- The resulting backup from the internal `wsl --export ...` command is saved to a subdirectory of the user who ran the script (eg: `$env:USERPROFILE\backup`); however, specifying the `-Destination ...` parameter with the registration script will allow that to be changed for scheduled backups. Likewise, if you want to perform an ad-hoc backup by executing the the `.\Run-WSL2Backup.ps1` script directly, the `-DestinationPath ...` option will allow specifying the saved backup location. An example of the later is: `.\Run-WSL2Backup.ps1 -DestinationPath D:\hot-disk\backups\wsl2\ubuntu`
- The default target distribution is specified as `Ubuntu`; but specifying some other installed distribution is perfectly fine. During registration, unregistering, or an ad-hoc backup, add the `-Distribution ...` option to the respective script.
- The default period to run the backup and restart tasks is set to on or after `1AM` locally on `Sunday`. These can be changed manually in the task scheduler of course, or by specifying the necessary options of `-Time ...` and `-DayOfWeek ...` during registration. Scheduled time is in the form of HH:mm with an 'AM' or 'PM' indicator immediately following. The day of the week is a string matching the system names for the days of the week.
- Output redirection can be used to get a more verbose output by exposing the log messages (which are typically 'Information' output stream tagged) to the success output stream when appending '6>&1' to the end of an ad-hoc script invocation. More information on redirection can be found in the Microsoft documentation
  [about redirection](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_redirection?view=powershell-7.1)

### Purpose and how to use each script in the default use-case

#### Register the scheduled backup tasks

- Script: `.\Register-WSL2Backup.ps1`
- Returns: On success, a textual table summary of associated, registered task paths, task names, and status.
- On Error: A message when a task or associated task is not registered given whatever parameters are specified, if any

#### Get the scheduled backup tasks

- Script: `.\Get-WSL2Backup.ps1`
- Returns: A list of tasks registered to a given set of service-identifiers (eg, default is `backup` and `docker`).
- On Error: Typically, it will error only if no tasks are found using the given service identifiers.

#### Unregister the scheduled backup tasks

- Script: `.\Unregister-WSL2Backup.ps1`
- Returns: A prompt for confirmation that you want each task removed from the scheduler.
- On Error: Failure messages when unable to remove expected scheduled tasks associated with the service identifier (eg: `backup`). Typically, failure occurs if the service identifier does not match the current configuration or a lack of adequate, elevated permissions to remove a specific task by the executing user.

#### Ad-hoc execution of the backup script

- Script: `.\Run-WSL2Backup.ps1`
- Verbose Output Example: `.\Run-WSL2Backup.ps1 6>&1`
- Returns: A tar archive in the `$env:USERPROFILE\backup` directory based on a snapshot of the `Ubuntu` WSL2 distribution for the executing user. Specifying the `-Distribution ...` option during registration or during this ad-hoc backup will allow you to target a distribution other than the conventional default, Ubuntu. The file name for the archive by default uses a format of `<distribution>-<date of execution>.tar`. For example: `Ubuntu-20210426.tar`
- On Error: ...

#### Ad-hoc restart the docker suite

- Script: `.\Restart-Suite.ps1`
- Returns: A freshly started docker desktop suite of services and client application.
- On Error: ...
