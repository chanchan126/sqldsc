<#
    .SYNOPSIS
        Network configuration to allow communication with the SQL Server 
    .DESCRIPTION
        Sets SQL Server instance settings to enable TCP and SQL ports or enable dynamic port option
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
        Boolean. $true = enable, $false = disable.

    .EXAMPLE
        Enable SQL instance TCP and set default SQL port
        Set-SqlDscNetwork -IsEnabled
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
        $InstanceName,

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
    Try {
        
        If(!$InstanceName -or $InstanceName -eq '') {
            $InstanceName = 'MSSQLSERVER'
        }
        
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
    Catch {
        Write-Error "$_"
    }
}