<#
    .SYNOPSIS
        Server level auditing for successful and/or failed logins 
    .DESCRIPTION
	    Sets auditing level for server logins
    .PARAMETER SqlServer
        String. Contains the SQL Server name to connect to.
    .PARAMETER InstanceName
        String. Name of the SQL instance.
    .PARAMETER AuditLevel
        UInt64. sets the level of auditing for logins on the server. 0 = none, 1 = success, 2= failure, 3 = all 
    
    .EXAMPLE
        login to default instance and set audit level to All
        SqlSmoServerAuditLogin -AuditLevel 3

        login to named instance and set audit level to failure
        SqlSmoServerAuditLogin -InstanceName 'NAMEDINSTANCE' -AuditLevel 2
#>

function Set-SqlSmoServerAuditLogin
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
        [System.UInt64]
        $AuditLevel

    )

    $ErrorActionPreference = "Stop"
    Try {
        
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
                $Assembly = [System.Reflection.Assembly]::LoadWithPartialName($Assembly) | Out-Null
        }

        $SMO = New-Object "Microsoft.SqlServer.Management.Smo.Wmi.Server" ($SqlServerName)

        $SMO.Settings.AuditLevel = $AuditLevel
        $SMO.Alter()

        If ($AuditLevel -eq 0) { Write-Host "Audit Level for login is set to None" }
        If ($AuditLevel -eq 1) { Write-Host "Audit Level for login is  set to Success" }
        If ($AuditLevel -eq 2) { Write-Host "Audit Level for login is  set to Failure" }
        If ($AuditLevel -eq 3) { Write-Host "Audit Level for login is  set to All" }
    }

    Catch { 
        Write-Error "$_" 
    }

}

            