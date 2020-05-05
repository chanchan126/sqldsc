<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER SqlServer
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        Name of the SQL instance.
    .PARAMETER $AuditLevel
        Uint64. set the value for login auditing. 0 = none, 1 = Success, 2 = Failure, 3 = All
    .EXAMPLE
        login to default instance and set audit level to All
        Set-SqlSmoAuditLevel -AuditLevel 3

        login to named instance and set audit level to failure
        Set-SqlSmoAuditLevel -InstanceName 'NAMEDINSTANCE -AuditLevel 2
#>

function Set-SqlSmoAuditLevel
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
        [System.Uint64]
        $AuditLevel,

        [Parameter()]
        [switch]
        $RestartService

    )

    $ErrorActionPreference = "Stop"
    
    If (!$InstanceName -or $InstanceName -eq 'MSSQLSERVER'){
        $InstanceName =''
        $SQLInstance = $Hostname
    }
    Else{
        $SQLInstance = (Join-Path "$Hostname\" "$InstanceName")
    }
    
    Try {
     
        $Assemblies=
        "Microsoft.SqlServer.Management.Common",
        "Microsoft.SqlServer.Smo",
        "Microsoft.SqlServer.SqlWmiManagement ",
        "Microsoft.SqlServer.SqlEnum"
 
        Foreach ($Assembly in $Assemblies) {
            $Assembly = [System.Reflection.Assembly]::LoadWithPartialName($Assembly)
        }

        $Object = "Microsoft.SqlServer.Management.Smo." 
        $SMO = New-Object ($Object + "Server") -ArgumentList $SQLInstance

        If ($AuditLevel -eq 0) { 
            $SMO.Settings.AuditLevel = 0
            $SMO.Alter()
            Write-Host "Audit Level set to None" -BackgroundColor DarkGreen -ForegroundColor White
        }
        If ($AuditLevel -eq 1) { 
            $SMO.Settings.AuditLevel = 1
            $SMO.Alter()            
            Write-Host "Audit Level set to Success" -BackgroundColor DarkGreen -ForegroundColor White
        }
        If ($AuditLevel -eq 2) { 
            $SMO.Settings.AuditLevel = 2
            $SMO.Alter()        
            Write-Host "Audit Level set to Failure" -BackgroundColor DarkGreen -ForegroundColor White
        }
        If ($AuditLevel -eq 3) { 
            $SMO.Settings.AuditLevel = 3
            $SMO.Alter()        
            Write-Host "Audit Level set to All" -BackgroundColor DarkGreen -ForegroundColor White 
        }
        ElseIf($AuditLevel -lt 0 -or $AuditLevel -gt 3) {
            Write-Host "Invalid Audit Level Please choose from 0-3" -BackgroundColor Red -ForegroundColor White 
        }
    }
    
    Catch { Write-Error $_ }

}

            