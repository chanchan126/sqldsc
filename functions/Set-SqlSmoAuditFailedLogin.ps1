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
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt64]
        $AuditLevel,

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

        $SMO = New-Object "Microsoft.SqlServer.Management.Smo.Wmi.Server" ($SqlServerName)

        $SMO.Settings.AuditLevel = $AuditLevel
        $SMO.Alter()

        If ($AuditLevel -eq 0) { Write-Host "Audit Level set to None" }
        If ($AuditLevel -eq 1) { Write-Host "Audit Level set to Success" }
        If ($AuditLevel -eq 2) { Write-Host "Audit Level set to Failure" }
        If ($AuditLevel -eq 3) { Write-Host "Audit Level set to All" }
        


    }

    Catch { Write-Error $_ }

}

            