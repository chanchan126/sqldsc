<#
    .SYNOPSIS
        Install SQL Server default or named instance. 
    .PARAMETER SQLSetupPath
        String containing the location of the setup exe file.
    .PARAMETER SQLUpdatePath
        String containing the location of the setup exe file.
    .PARAMETER SQLInstanceName
        String containing the name of the instance. if value is blank, default instance will be installed
    .PARAMETER SQLCollation
        String containing the instance collation. if value is blank, default collation is SQL_Latin1_General_CP1_CI_AS
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
        $SQLInstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.String]
        $SQLCollation = 'SQL_Latin1_General_CP1_CI_AS',

        [Parameter()]
        [System.String[]]
        $SQLSysAdminAccounts = $env:USERNAME,

        [Parameter()]
        [System.String]
        $SQLInstanceDrive = 'D:\MSSQL',

        [Parameter()]
        [System.String]
        $SQLDataDrive = 'E:\MSSQL',


        [Parameter()]
        [System.String]
        $SQLLogDrive = 'F:\MSSQL',

        [Parameter()]
        [System.String]
        $SQLTempdbDrive  = 'G:\MSSQL',

        [Parameter()]
        [System.String]
        $SQLBackupDrive  = 'H:\MSSQL',

        [Parameter()]
        [System.uint32]
        $TempDBFileSize = 128,

        [Parameter()]
        [System.uint32]
        $TempDBFileGrowth = 64,

        [Parameter()]
        [System.uint32]
        $TempDBLogFileSize = 128,

        [Parameter()]
        [System.uint32]
        $TempDBLogFileSizeGrowth = 64,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SVCaccount,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SVCpassword,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SAaccount,

        [Parameter(Mandatory=$true)]
        [System.String]
        $SApassword,

        [Parameter()]
        [Switch]
        $ForceReboot
    )


    #Set InstanceName variable if not provided
    If(!$SQLInstanceName) {
        $SQLInstanceName = 'MSSQLSERVER'
    }

    #Service Account
    $SVCPass = ConvertTo-SecureString "$SVCpassword" -AsPlainText -Force
    $SVCpsCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($SVCaccount, $SVCPass)

    #SA Account
    $SAPass = ConvertTo-SecureString "$SApassword" -AsPlainText -Force
    $SApsCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($SAaccount, $SAPass)

    #Set TempDBfiles based on number of cores
    $cpuCores=Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -ExpandProperty 'NumberOfCores';
    [uint32]$tempDBFilesCount = $cpuCores.Count
    
    if ($tempDBFilesCount.Count -gt 8) {
        [uint32]$tempDBFilesCount = 8
    }

    #region: INSTALL SQL SERVER #
    $SQLMajorVersion = (Get-Item -Path $(Join-Path $SQLSetupPath 'setup.exe')).VersionInfo.ProductVersion.Split('.')[0]
    $BrowserSvcStartupType = if ($SQLInstanceName -eq 'MSSQLSERVER') { 'Disabled' } else { 'Automatic' }

    If ($ForceReboot) {

    $sqlSetupParams = @{
        SourcePath             = $SQLSetupPath
        InstanceName           = $SQLInstanceName
        Features               = 'SQLENGINE'
        SQLCollation           = $SQLCollation
        SQLSvcAccount          = $SVCpsCred
        AgtSvcAccount          = $SVCpsCred
        SQLSysAdminAccounts    = $SQLSysAdminAccounts
        SecurityMode           = "SQL"
        SAPwd                  = $SApsCred
        InstallSharedDir       = "C:\Program Files\Microsoft SQL Server"
        InstallSharedWOWDir    = "C:\Program Files (x86)\Microsoft SQL Server"
        FeatureFlag            = @('DetectionSharedFeatures')
        InstanceDir            = $SQLInstanceDrive
        InstallSQLDataDir      = $SQLInstanceDrive
        SQLUserDBDir           = (Join-Path $SQLDataDrive "MSSQL$SQLMajorVersion.$SQLInstanceName\MSSQL\DATA")
        SQLUserDBLogDir        = (Join-Path $SQLLogDrive  "MSSQL$SQLMajorVersion.$SQLInstanceName\MSSQL\LOG")
        SQLTempDBDir           = (Join-Path $SQLTempdbDrive "MSSQL$SQLMajorVersion.$SQLInstanceName\MSSQL\TEMPDB")
        SQLTempDBLogDir        = (Join-Path $SQLTempdbDrive "MSSQL$SQLMajorVersion.$SQLInstanceName\MSSQL\TEMPDB")
        SQLBackupDir           = (Join-Path $SQLBackupDrive  "MSSQL$SQLMajorVersion.$SQLInstanceName\MSSQL\BACKUP")
        SqlTempdbFileCount     = $tempDBFilesCount
        SqlTempdbFileSize      = $TempDBFileSize
        SqlTempdbFileGrowth    = $TempDBFileGrowth
        SqlTempdbLogFileSize   = $TempDBLogFileSize
        SqlTempdbLogFileGrowth = $TempDBLogFileSizeGrowth
        BrowserSvcStartupType  = $BrowserSvcStartupType
}

If($TempDBFileSize -and $TempDBFileGrowth -and $TempDBLogFileSize -and $TempDBLogFileSizeGrowth) {
    $sqlSetupParams.Add ('TempDBFileSize',$TempDBFileSize)
    $sqlSetupParams.Add ('TempDBFileGrowth',$TempDBFilTempDBFileGrowtheSize)
    $sqlSetupParams.Add ('TempDBLogFileSize',$TempDBLogFileSize)
    $sqlSetupParams.Add ('TempDBLogFileSizeGrowth',$TempDBLogFileSizeGrowth)
}

If ($ForceReboot) { 
    [boolean]$ForceRB = $true
    $sqlSetupParams.Add ('ForceReboot',$ForceRB) }

If ($SQLUpdatePath) {
    $sqlSetupParams.Add ('UpdateEnabled','True')
    $sqlSetupParams.Add ('UpdateSource',$SQLUpdatePath)
}

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