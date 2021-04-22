$backupTaskName = "* backup"
try {
    Get-ScheduledTask -TaskName $backupTaskName
}
catch {
    Write-Output "Unable to find any tasks named $backupTaskName"
}

$restartDockerTaskName = "*Docker*"
try {
    Get-ScheduledTask -TaskName $restartDockerTaskName
}
catch {
    Write-Output "Unable to find any tasks named $restartDockerTaskName"
}
