<#
.SYNOPSIS 
A common logging implmentation that can be reused throughout a project.

.DESCRIPTION
A common logging implmentation that can be reused throughout a project.  It is included by 
sourcing in the file within a consuming script prior to a caller executing the consumed method(s) of `Log` with the appropriate parameters.


.NOTES 
Output redirection can be used to get a more verbose output by
exposing the log messages when appending '6>&1' to the end of script invocation
whether arguments are specified or not as most messages are directed to the
'Information' stream.  More information on redirection can be found in the Microsoft documentation
[about redirection](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_redirection?view=powershell-7.1).
.EXAMPLE
# 'sourcing' in the log message function
. "$PSScriptRoot\Log-Message.ps1"
# call the Log method
Log "Hello World, Log-Message.ps1"

#>
function Log {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$LogLevel = 'Information'
    )

    $timestamp = $(Get-Date -Format "HH:mm:ss")
    $logMessageFormatted = "$timestamp - $Message"

    switch ($LogLevel) {
        'Error' { 
            Write-Error -Message $logMessageFormatted
        }
        'Warning' { 
            Write-Warning -Message $logMessageFormatted
        }
        'Information' { 
            Write-Information -MessageData $logMessageFormatted
        }
        'Verbose' { 
            Write-Verbose -Message $logMessageFormatted
        }
        'Debug' { 
            Write-Debug -Message $logMessageFormatted
        }
        default { 
            throw "Unknown log level: $_, but here is your message: $Message" 
        }
    }
}
