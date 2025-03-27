<#
    .SYNOPSIS
        SQL Server installation with default or named instance. 
    .DESCRIPTION
        Sets target server to be installed with SQL Server instance including options aligned to SQL installation standards.
    .PARAMETER SQLSetupPath
        String containing the location of the setup exe file.
    .PARAMETER SQLUpdatePath
        String containing the location of the setup exe file.
    .PARAMETER InstanceName
        String containing the name of the instance. if value is blank, default instance will be installed
    .PARAMETER Features
        String containing the features to be installed. ex. 'SQLENGINE' or 'SQLENGINE,IS' or 'SQLENGINE,IS,AS'
    .PARAMETER SQLCollation
        String containing the instance collation. if value is blank, default collation is Latin1_General_CI_AS
    .PARAMETER SecurityMode
        String containing login modes for the instance. 'Windows" for windows authentication only, 'SQL' for mixed mode
    .PARAMETER SQLSysAdminAccounts
        String array containing the Windows local or AD accounts
    .PARAMETER SQLInstanceDrive
        String full path for the SQL binaries
    .PARAMETER SQLDataDrive
        String full path for the user data files
    .PARAMETER SQLLogDrive
        String full path for the user log files
    .PARAMETER SQLTempdbDrive
        String full path for the tempdb files
    .PARAMETER SQLBackupDrive
        String full path for backups
    .PARAMETER TempDBFileSize
        UINT32 size of the tempdb files
    .PARAMETER TempDBFileGrowth
        UINT32 growth size for the files
    .PARAMETER TempDBLogFileSize
        UINT32 size of the tempdb log file
    .PARAMETER TempDBLogFileSizeGrowth
        UNIT32 growth size extension of the tempdb log
    .PARAMETER SVCaccount
        String local or domain account for SQL Engine service
    .PARAMETER SVCpassword
        String password for SQL Engine service
    .PARAMETER AgtSVCaccount
        String local or domain account for SQL Agent service
    .PARAMETER AgtSVCpassword
        String password for SQL Agent service
    .PARAMETER SApassword
        String password for logging in as SA account. mandatory
    .PARAMETER ForceReboot
    
    .EXAMPLE
    Install SQL Server with default instance and default options
    Set-SqlDscInstallSqlServer -SQLSetupPath "Z:\" -SApassword 'ThisisPassword123'
#>

function Set-SqlDscInstallSqlServer
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLSetupPath,

        [Parameter()]
        [System.String]
        $SQLUpdatePath,

        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.String]
        $SQLCollation,

        [Parameter()]
        [ValidateSet("SQL","Windows")]
        [System.String]
        $SecurityMode,

        [Parameter()]
        [System.String[]]
        $SQLSysAdminAccounts,

        [Parameter()]
        [System.String]
        $SQLInstanceDrive,

        [Parameter()]
        [System.String]
        $SQLDataDrive,


        [Parameter()]
        [System.String]
        $SQLLogDrive,

        [Parameter()]
        [System.String]
        $SQLTempdbDrive,

        [Parameter()]
        [System.String]
        $SQLBackupDrive,

        [Parameter()]
        [System.int64]
        $TempDBFileSize, #1024

        [Parameter()]
        [System.int64]
        $TempDBFileGrowth, #256

        [Parameter()]
        [System.int64]
        $TempDBLogFileSize, #8

        [Parameter()]
        [System.int64]
        $TempDBLogFileSizeGrowth, #512

        [Parameter()]
        [System.String]
        $SVCaccount,

        [Parameter()]
        [System.String]
        $SVCpassword,
        
        [Parameter()]
        [System.String]
        $AgtSVCaccount,

        [Parameter()]
        [System.String]
        $AgtSVCpassword,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SApassword,

        [Parameter()]
        [System.Boolean]
        $ForceReboot
    )

    try {
        $ErrorActionPreference = "Stop"
        
        #Set InstanceName variable if not provided
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        #Set SQL Collation if not provided
        If (!$SQLCollation) {
            $SQLCollation = 'SQL_Latin1_General_CP1_CI_AS'
        }

        If(!$SecurityMode) {
            $SecurityMode = 'Windows'
        }

        If(!$SQLSysAdminAccounts) {
        $SQLSysAdminAccounts = $env:USERNAME
        }

        If(!$SQLInstanceDrive) {
        $SQLInstanceDrive = 'D:\MSSQL'
        }
        
        If(!$SQLDataDrive) {
        $SQLDataDrive = 'E:\MSSQL'
        }
        
        If(!$SQLLogDrive) {
        $SQLLogDrive = 'F:\MSSQL'
        }
        
        If(!$SQLTempdbDrive) {
        $SQLTempdbDrive  = 'G:\MSSQL'
        }
        
        If(!$SQLBackupDrive) {
        $SQLBackupDrive  = 'H:\MSSQL'
        }
    
        #Set Defaults
        If ($SApassword) {
            $SAaccount = "sa"
            $SAPass = ConvertTo-SecureString -String "$SApassword" -AsPlainText -Force
            $SApsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($SAaccount, $SAPass)
        }
        Else {
            Write-Error "SA password required. Please input a value"
        }
        
        #set tempdb files count
        $cpuCores=Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -ExpandProperty 'NumberOfCores';
        [uint32]$tempDBFilesCount = $cpuCores.Count
    
        if ($tempDBFilesCount.Count -gt 8) {
            [uint32]$tempDBFilesCount = 8
        }

        #set startup type
        $SQLMajorVersion = (Get-Item -Path $(Join-Path $SQLSetupPath 'setup.exe')).VersionInfo.ProductVersion.Split('.')[0]
        $BrowserSvcStartupType = if ($InstanceName -eq 'MSSQLSERVER') { 'Disabled' } else { 'Automatic' }

        #Set SQL DSC install parameters
            $sqlSetupParams = @{
                SourcePath             = $SQLSetupPath
                InstanceName           = $InstanceName
                Features               = 'SQLENGINE'
                SQLCollation           = $SQLCollation
                SQLSysAdminAccounts    = $SQLSysAdminAccounts
                SAPwd                  = $SApsCred
                InstallSharedDir       = "C:\Program Files\Microsoft SQL Server"
                InstallSharedWOWDir    = "C:\Program Files (x86)\Microsoft SQL Server"
                FeatureFlag            = @('DetectionSharedFeatures')
                InstanceDir            = $SQLInstanceDrive
                InstallSQLDataDir      = $SQLInstanceDrive
                SQLUserDBDir           = (Join-Path $SQLDataDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\DATA")
                SQLUserDBLogDir        = (Join-Path $SQLLogDrive  "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\LOG")
                SQLTempDBDir           = (Join-Path $SQLTempdbDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\TEMPDB")
                SQLTempDBLogDir        = (Join-Path $SQLTempdbDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\TEMPDB")
                SQLBackupDir           = (Join-Path $SQLBackupDrive  "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\BACKUP")
                SqlTempdbFileCount     = $tempDBFilesCount
                BrowserSvcStartupType  = $BrowserSvcStartupType
                AgtSvcStartupType      = 'Automatic'
        }

        #set service accounts
        If($SVCaccount -and $SVCpassword) {
            $SVCPass = ConvertTo-SecureString -String "$SVCpassword" -AsPlainText -Force
            $SVCpsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($SVCaccount, $SVCPass)
            $sqlSetupParams.Add('SQLSvcAccount',$SVCpsCred)
            
            If (!$AgtSVCaccount) {
                $sqlSetupParams.Add('AgtSvcAccount',$SVCpsCred)
            }
            If ($AgtSVCaccount -and $AgtSVCpassword) {
                $AgtSVCPass = ConvertTo-SecureString -String "$AgtSVCpassword" -AsPlainText -Force
                $AgtSVCpsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($AgtSVCaccount, $AgtSVCPass)
                $sqlSetupParams.Add('AgtSvcAccount',$AgtSVCpsCred)
            }
        }

        #set security mode
        If($SecurityMode -eq 'SQL') {
            $sqlSetupParams.Add('SecurityMode',$SecurityMode)
        }
                
        #set and only add tempdb if major version <= 13
        If($SQLMajorVersion -ge 13) {
            If($TempDBFileSize -or $TempDBFileGrowth -or $TempDBLogFileSize -or $TempDBLogFileSizeGrowth) {
                If($TempDBFileSize -and $TempDBFileGrowth -and $TempDBLogFileSize -and $TempDBLogFileSizeGrowth) {
                    $sqlSetupParams.Add('SqlTempdbFileSize',$TempDBFileSize)
                    $sqlSetupParams.Add('SqlTempdbFileGrowth',$TempDBFileGrowth)
                    $sqlSetupParams.Add('SqlTempdbLogFileSize',$TempDBLogFileSize)
                    $sqlSetupParams.Add('SqlTempdbLogFileGrowth ',$TempDBLogFileSizeGrowth)
                }
                Else {
                    Write-Error "Missing TempDB values, please fill in the TempDB parameters"
                }
            }
        }
        
        #include CU/hotfix if there is any
        If ($SQLUpdatePath) {
            $sqlSetupParams.Add('UpdateEnabled','True')
            $sqlSetupParams.Add('UpdateSource',$SQLUpdatePath)
        }

        #set reboot
        If ($ForceReboot -eq $true) { 
            $sqlSetupParams.Add('ForceReboot',$ForceReboot) 
        }

        #install sql instance
        If ($SQLSetupPath) {
            $testSqlSetup = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Test -Verbose
            If (!$testSqlSetup) {
                Write-Host 'Installing(SqlSetup)...' -BackgroundColor White -ForegroundColor Black
                Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Set -Verbose
            }
             
            Else {
            Write-Host 'Skipping(SqlSetup)... SQL Instance already exists.' -BackgroundColor Yellow -ForegroundColor Black
            } 
        }
        
        Else {
            Write-Host 'Skipping(SqlSetup)... No setup path provided.' -BackgroundColor Yellow -ForegroundColor Black
        }
    } 
     
    Catch{
        Write-Error "Error. Please check your command string: $_"
    }
    
    $SQLInstallVersion = $SQLMajorVersion + "0"
    Get-Content "C:\Program Files\Microsoft SQL Server\$SQLInstallVersion\Setup Bootstrap\Log\Summary.txt" | Select-Object -First 8

}