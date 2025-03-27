<#
    .SYNOPSIS
        Network configuration to allow communication with the SQL Server 
    .DESCRIPTION
        Sets SQL Server instance settings to enable TCP and SQL ports or enable dynamic port option
    .PARAMETER SqlServer
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Name of the SQL instance.
    .PARAMETER IsTCPEnabled
        Boolean. Determines whether TCP is enabled or not. $true = enable, $false = disable. Default is set to true
    .PARAMETER TCPDynamicPort
        Boolean. Determines whether TCP Dynamic Port is enabled or not.$true = enable, $false = disable. Default is set to false
    .PARAMETER TCPPort
        String. Default port is 1433
    .PARAMETER RestartService
        Boolean. $true = enable, $false = disable.

    .EXAMPLE
        Enable SQL instance TCP and set default SQL port
        Set-SqlDscNetwork -IsTCPEnabled
#>

function Set-SqlDscNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SqlServerName,

        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Boolean]
        $IsTCPEnabled,

        [Parameter()]
        [System.Boolean]
        $TCPDynamicPort,

        [Parameter()]
        [ValidateNotNull()]
        [System.String]
        $TCPPort,

        [Parameter()]
        [System.Boolean]
        $RestartService

    )
    Try {
        
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If(!$IsTCPEnabled) {
            $IsTCPEnabled = $true
        }

        If(!$TCPDynamicPort) {
            $TCPDynamicPort = $false
        }

        If(!$RestartService) {
            $RestartService = $false
        }

        If(!$TCPPort){
            $TCPPort = '1433'            
        }

        $tcp = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            ProtocolName = 'TCP'
            IsEnabled    = $IsTCPEnabled
            TCPDynamicPort  = $TCPDynamicPort
            TCPPort         = $TCPPort
            RestartService  = $RestartService
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