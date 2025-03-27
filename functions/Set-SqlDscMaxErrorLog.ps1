<#
    .SYNOPSIS
        Configuration option for setting Maximum number error log files 
    .Description
        Sets configuration option value for CLR
    .PARAMETER SqlServerName
        String. containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER MaxNumLogs
        Integer containing the max number of logs to be created for the instance.
    .PARAMETER ErrorLogSizeKB
        Integer containing the max size of the log before rolling over.
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
                
    .EXAMPLE
    Connect to named instance using windows authentication
    Set-SqlDscDatabaseAudit -InstanceName 'CHAN' -ServerAuditName 'CHAN_Audit' -ServerAuditFileSize '50MB' -WindowsCred "adsql\sql" -WindowsPassword "!%$^FHC" -Verbose
    
#>

function Set-SqlDscMaxErrorLog
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
        [System.Int64]
        $MaxNumLogs,

        [Parameter()]
        [System.Int64]
        $ErrorLogSizeKB,

        [Parameter()]
        [System.String]
        $WindowsCred,

        [Parameter()]
        [System.String]
        $WindowsPassword
    )
    try {
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        #Set ServerName for Invoke-Sqlcmd
        If ($InstanceName -eq 'MSSQLSERVER'){
            $SQLInstance = $SqlServerName
        }
        Else{
            $SQLInstance = (Join-Path "$SqlServerName\" "$InstanceName")
        }
        
        #Set Max number of error logs    
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        
        $Object = "Microsoft.SqlServer.Management.Smo." 
        $SMO = New-Object ($Object + "Server") -ArgumentList $SQLInstance
        $CurrentMaxErrorLog = $SMO.NumberOfLogFiles
        
        $SetMaxErrorLog = "
            USE [master];
            EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, $MaxNumLogs;
            EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'ErrorLogSizeInKb', REG_DWORD, $ErrorLogSizeKB;
            "
        $MaxErrorLog = @{
            ServerInstance = $SQLInstance
            SetQuery = $SetMaxErrorLog
            TestQuery = $SetMaxErrorLog
            GetQuery = $SetMaxErrorLog
            QueryTimeout = 20
        }  

        If ($WindowsCred){
            $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
            $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
            $SqlParam.Add('PsDscRunAsCredential',$WindowsPSCred)
        }

        If ($CurrentMaxErrorLog -ne $MaxNumLogs){
            Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $MaxErrorLog -Method Set -Verbose
            Write-Host "Max number of error log files is set to $MaxNumLogs with $ErrorLogSizeKB in size" -BackgroundColor DarkGreen -ForegroundColor White
        }

        Else {
            Write-Host "Max number of error log files is already set" -BackgroundColor DarkGreen -ForegroundColor White
        }

    }

    Catch { 
        Write-Error "$_" }
       
}