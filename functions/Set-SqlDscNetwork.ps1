<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER SqlServer
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        Name of the SQL instance.
    .PARAMETER IsEnabled
        $true = enable, $false = disable. 
    .PARAMETER TCPDynamicPort
        $true = enable, $false = disable.
    .PARAMETER TCPPort
        String value. Default port is 1433
    .PARAMETER RestartService
        $true = enable, $false = disable.

#>

function Set-SqlDscNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SqlServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [switch]
        $IsEnabled,

        [Parameter()]
        [switch]
        $TCPDynamicPort,

        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $TCPPort = '1433',

        [Parameter()]
        [switch]
        $RestartService

    )

    $tcp = @{
        ServerName = $SqlServerName
        InstanceName = $InstanceName
        ProtocolName = 'TCP'
        IsEnabled    = [boolean]$IsEnabled
        TCPDynamicPort  = [boolean]$TCPDynamicPort
        TCPPort         = $TCPPort
        RestartService  = [boolean]$RestartService
    }
    
    $tcptest = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerNetwork -Property $tcp -Method Test -Verbose

    If ($tcptest -eq $false){
        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerNetwork -Property $tcp -Method Set -Verbose
        If($Port -in (1433,1434)){
            Write-Host "Port used is not recommended. Please choose another port for more security" -BackgroundColor Red -ForegroundColor White
        }
        Else{
        Write-Host "Port used is in compliance to SQL CIS" -BackgroundColor DarkGreen -ForegroundColor White
        }
    }
    Else {
    Write-Host "$Port already in use. Please choose different port" -BackgroundColor Red -ForegroundColor White -InformationAction Stop
}
}