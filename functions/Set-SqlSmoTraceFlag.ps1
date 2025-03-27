<#
    .SYNOPSIS
        SQL Server instance configuration for setting trace flags
    .DESCRIPTION
        Sets trace flag for a SQL Server instance 
    .PARAMETER SqlServer
        String. containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Name of the SQL instance.
    .PARAMETER StartupParamValues
        String. containing the value of trace flags. if multiple values, separate them with a comma. ex. '-T1118;-T3226' 
    .PARAMETER RestartService
        $true = enable, $false = disable.
    
    .EXAMPLE
        Named instance with service restart
            Set-SqlSmoTraceFlag -InstanceName 'CHAN' -StartupParamValues '-T1118;-T3226' -RestartService
        
        Default instance without service restart
            Set-SqlSmoTraceFlag -StartupParamValues '-T2993'


#>

function Set-SqlSmoTraceFlag
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
        [System.String]
        $StartupParamValues,

        [Parameter()]
        [switch]
        $RestartService

    )
    $ErrorActionPreference = "Stop"

    If(!$SqlServerName) {
        $SqlServerName = $env:COMPUTERNAME
    }

    If(!$InstanceName) {
        $InstanceName = 'MSSQLSERVER'
    }

    $Assemblies=
        "Microsoft.SqlServer.Smo",
        "Microsoft.SqlServer.SqlWmiManagement "
 
    Foreach ($Assembly in $Assemblies) {
        [System.Reflection.Assembly]::LoadWithPartialName($Assembly) | Out-Null
    }
    
    $SMO = New-Object "Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer" -ArgumentList $SqlServerName
    
    If ($InstanceName -ne 'MSSQLSERVER') {
        $Service = $SMO.Services| Where-Object { $_.Name -eq 'MSSQL$' + $InstanceName }
    }
    ElseIf ($InstanceName -eq 'MSSQLSERVER') {
        $Service = $SMO.Services| Where-Object { $_.Name -eq 'MSSQLSERVER' }
    }

    If ($StartupParamValues.Substring(0,1) -ne ';') {
        If($Service.StartupParameters -match $StartupParamValues) {
            Write-Host "Trace flag already existing" -BackgroundColor DarkGreen -ForegroundColor Yellow
        }
        Else {
            $StartupParamNew = $StartupParamValues.Insert(0,';')
            $Service.StartupParameters += $StartupParamNew
            $Service.StartupParameters
            $Service.Alter()
            Write-Host "Trace flag has been set. Please restart service to take effect" -BackgroundColor DarkGreen -ForegroundColor White
        }
    }
    
    Else {
        If($Service.StartupParameters -match $StartupParamValues) {
            Write-Host "Trace flag already existing" -BackgroundColor DarkGreen -ForegroundColor Yellow
        }
        Else {
            $Service.StartupParameters += $StartupParamValues    
            $Service.StartupParameters
            $Service.Alter()
            Write-Host "Trace flag has been set. Please restart service to take effect" -BackgroundColor DarkGreen -ForegroundColor White
        }
    }
    
    If ($RestartService) {
        If ($InstanceName -eq 'MSSQLSERVER' ) {
            Stop-Service -Name 'MSSQLSERVER' -Force    
            Start-Service -Name 'MSSQLSERVER'
            Start-Service -name 'SQLSERVERAGENT'           
            Write-Host "Default instance has been restarted" -BackgroundColor DarkGreen -ForegroundColor White
        }
        ElseIf ($InstanceName -ne 'MSSQLSERVER' )  {
            $NamedDBService = "MSSQL$" + $InstanceName
            $NamedAgentService = "SQLAGENT$" + $InstanceName
            Stop-Service -Name $NamedDBService -Force
            Start-Service -Name $NamedDBService
            Start-Service -name $NamedAgentService
            Write-Host "$InstanceName instance has been restarted" -BackgroundColor DarkGreen -ForegroundColor White
        }
        
    }
}

