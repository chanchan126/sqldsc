<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER SqlServer
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        Name of the SQL instance.
    .PARAMETER StartupParamValues
        String containing the value of trace flags. if multiple values, separate them with a comma. ex. '-T1118;-T3226' 
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
        $SqlServerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.String]
        $StartupParamValues,

        [Parameter()]
        [switch]
        $RestartService

    )
    $ErrorActionPreference = "Stop"

    $Assemblies=
    "Microsoft.SqlServer.Management.Common",
    "Microsoft.SqlServer.Smo",
    "Microsoft.SqlServer.SqlWmiManagement "
 
    Foreach ($Assembly in $Assemblies) {
        [System.Reflection.Assembly]::LoadWithPartialName($Assembly) | Out-Null
    }
    
    $SMO = New-Object "Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer" -ArgumentList $sqlserver

    If ($InstanceName) {
        $Service = $SMO.Services| Where-Object { $_.Name -eq 'MSSQL$' + $InstanceName }
    }
    Else {
        $Service = $SMO.Services| Where-Object { $_.Name -eq 'MSSQLSERVER' }
    }

    If ($StartupParamValues.Substring(0,1) -ne ';') {
    $StartupParamNew = $StartupParamValues.Insert(0,';')
    $Service.StartupParameters = $Service.StartupParameters + $StartupParamNew
    $Service.StartupParameters
    }
    
    Else {
    $Service.StartupParameters = $Service.StartupParameters + $StartupParamValues    
    $Service.StartupParameters
    }
    
    $Service.Alter()
    
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
    Else  {
            Write-Host "Trace flag has been set. Please restart service to take effect" -BackgroundColor DarkGreen -ForegroundColor White
    }

}

