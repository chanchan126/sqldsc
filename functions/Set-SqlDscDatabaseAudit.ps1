<#
    .SYNOPSIS
        Database level auditing configuration.
    .Description
        Sets database level auditing that captures all activities of the person logged in to the instance.
    .PARAMETER SqlServerName
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER ServerAuditName
        String. Contains the name of the Audit
    .PARAMETER ServerAuditFileSize
        String. Contains the size of the Audit file before rollover. It should contain the word "MB" Ex: '128MB'
    .PARAMETER AuditLogPath
        String. Contains the location for the Audit log. Default to SQL error log path
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
                
    .EXAMPLE
    Connect to named instance using windows authentication
    Set-SqlDscDatabaseAudit -InstanceName 'CHAN' -ServerAuditName 'CHAN_Audit' -ServerAuditFileSize '50MB' -WindowsCred "adsql\sql" -WindowsPassword "!%$^FHC"
    
#>

function Set-SqlDscDatabaseAudit
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
        $ServerAuditName,

        [Parameter()]
        [System.String]
        $ServerAuditFileSize,

        [Parameter()]
        [System.String]
        $AuditLogPath,

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
        If (!$InstanceName){
            $SQLInstance = $SqlServerName
        }
        Else{
            $SQLInstance = (Join-Path "$SqlServerName\" "$InstanceName")
        }
        
        $Assemblies=
            #"Microsoft.SqlServer.Management.Common",
            "Microsoft.SqlServer.Smo"
            #"Microsoft.SqlServer.SqlWmiManagement "
 
        Foreach ($Assembly in $Assemblies) {
            $Assembly = [System.Reflection.Assembly]::LoadWithPartialName($Assembly)
        }

        If (!$AuditLogPath) {
            $Object = "Microsoft.SqlServer.Management.Smo." 
            $SMO = New-Object ($Object + "Server") -ArgumentList $SQLInstance
            $AuditLogPath = $SMO.ErrorLogPath
        }

        If ($ServerAuditName){
            
            $AuditQuery = "
                IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = N'$ServerAuditName')
                CREATE SERVER AUDIT $ServerAuditName
                TO FILE (FILEPATH=N'$AuditLogPath',MAXSIZE=$ServerAuditFileSize,MAX_ROLLOVER_FILES=10,RESERVE_DISK_SPACE=ON)
                WITH (QUEUE_DELAY=1000,ON_FAILURE=CONTINUE);
		        ALTER SERVER AUDIT $ServerAuditName WITH (STATE = ON);
                IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = N'SQLServerAuditSpecification')
                CREATE SERVER AUDIT SPECIFICATION [SQLServerAuditSpecification]
                FOR SERVER AUDIT $ServerAuditName
                ADD (AUDIT_CHANGE_GROUP),
                ADD (DATABASE_CHANGE_GROUP),
                ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
                ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),
                ADD (DBCC_GROUP),
                ADD (FAILED_DATABASE_AUTHENTICATION_GROUP),
                ADD (FAILED_LOGIN_GROUP),
                ADD (SERVER_OBJECT_CHANGE_GROUP),
                ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP),
                ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
                ADD (SERVER_PERMISSION_CHANGE_GROUP),
                ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
                ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
                ADD (SERVER_STATE_CHANGE_GROUP),
                ADD (SUCCESSFUL_LOGIN_GROUP)
                WITH (STATE = ON);
                "

            $AuditParam = @{
                ServerInstance = $SQLInstance
                SetQuery = $AuditQuery
                TestQuery = $AuditQuery
                GetQuery = $AuditQuery
                QueryTimeout = 20
            }  
        
            If ($WindowsCred) {
                $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
                $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
                $AuditParam.Add('PsDscRunAsCredential', $WindowsPSCred)
            }

            $Test = Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $AuditParam -Method Test -Verbose

            If (!$Test) {
                Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $AuditParam -Method Set -Verbose
                Write-Host "Database audit has been enabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
    
            Else {
                Write-Host "Server level auditing for SQL Server already exists" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }
        Else {
            Write-Hos "Please provide Audit Name to proceed" -BackgroundColor Red -ForegroundColor White
        }

    }

    Catch { 
        Write-Error "$_" }
       
}