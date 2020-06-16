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
        $true = enable, $false = disable.

    .EXAMPLE
    Set default port and enable TCP
    Set-SqlSmoNetwork -IsEnabled 1 -EnableDynamicTCP 0 -RestartService 1

#>

function Set-SqlSmoNetwork
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
        [ValidateNotNull()]
        [System.String]
        $TCPPortValue = '1433',

        [Parameter()]
        [ValidateNotNull()]
        [switch]
        $EnableDynamicTCP,

        [Parameter()]
        [switch]
        $RestartService

    )
    $ErrorActionPreference = "Stop"

    Try {
        
        $Assemblies=
        "Microsoft.SqlServer.Management.Common",
        "Microsoft.SqlServer.Smo",
        "Microsoft.SqlServer.SqlWmiManagement "
 
        Foreach ($Assembly in $Assemblies) {
            $Assembly = [System.Reflection.Assembly]::LoadWithPartialName($Assembly) | Out-Null
        }
    
        $SMO = New-Object "Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer" ($SqlServerName)
        
        $TCP = $SMO.ServerInstances[$InstanceName].ServerProtocols['TCP']
        $TCPPort = $TCP.IPAddresses['IPAll'].IPAddressProperties['TcpPort']
        $TCPDynaPort = $TCP.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts']
    
        If ($IsEnabled) {
            If ($EnableDynamicTCP) {
                $TCP.IsEnabled = $IsEnabled
                $TCPPort.Value = ''
                $TCPDynaPort.Value = '0'
                Write-Host "TCP has been enabled and Dynamic TCP has been set" -BackgroundColor DarkGreen -ForegroundColor White
            }

            Else {
                $TCP.IsEnabled = $IsEnabled
                $TCPPort.Value = $TCPPortValue
                $TCPDynaPort.Value = ''
                Write-Host "TCP has been enabled with port $TCPPortValue"  -BackgroundColor DarkGreen -ForegroundColor White
            }
        }
        Else {
            $TCP.IsEnabled = $IsEnabled
            Write-Host "TCP has been disabled"  -BackgroundColor DarkGray -ForegroundColor White
        }
    
        If ($RestartService) {
            If ($InstanceName -eq 'MSSQLSERVER' ) {
                Stop-Service -Name 'MSSQLSERVER' -Force    
                $TCP.Alter()
                Start-Name 'MSSQLSERVER'
                Start-Service -name 'SQLSERVERAGENT'           
                Write-Host "Default instance has been restarted" -BackgroundColor DarkGreen -ForegroundColor White
            }
            ElseIf ($InstanceName -ne 'MSSQLSERVER' )  {
                $NamedDBService = "MSSQL$" + $InstanceName
                $NamedAgentService = "SQLAGENT$" + $InstanceName
                Stop-Service -Name $NamedDBService -Force
                $TCP.Alter()
                Start-Service -Name $NamedDBService
                Start-Service -name $NamedAgentService
                Write-Host "$InstanceName instance has been restarted" -BackgroundColor DarkGreen -ForegroundColor White
            }
            Else  {
            $TCP.Alter()
            }
        }   
    }
    
    Catch {
        Write-Error $_.Exception.Message
    }   
    
}
