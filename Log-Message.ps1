function Log {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$LogLevel = 'Information'
    )

    $timestamp = $(Get-Date -Format FileDateTime)
    $logMessageFormatted = "$timestamp - $Message"

    switch ($LogLevel) {
        'Error' { 
            Write-Error -Message $logMessageFormatted
        }
        'Warning' { 
            Write-Warning -Message $logMessageFormatted
        }
        'Information' { 
            Write-Information -MessageData $logMessageFormatted -Tags @($serviceIdentifier, "Restart-Suite")
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
