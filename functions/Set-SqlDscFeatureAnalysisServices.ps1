<#
    .SYNOPSIS
        SQL Server Analysis Services feature installation.  
    .DESCRIPTION
        Sets target server to be installed with SQL Server Analysis Services feature.
    .PARAMETER SQLSetupPath
        String. containing the location of the setup exe file.
    .PARAMETER InstanceName
        String. containing the name of the instance. if value is blank, default instance will be installed. If 2 or more instances are in the same server, just choose 1 instance as it is a shared service.
    .PARAMETER ASCollation
        String contains the AS collation. if value is blank, default collation is Latin1_General_CI_AS 
    .PARAMETER ASSysAdminAccounts
        String. accounts that will administer the AS
    .PARAMETER ASConfigDir
        String. Location for AS binary files. Default is in C:\Program Files\Microsoft SQL Server
    .PARAMETER ASDataDrive
        String. Location for the data files of AS. 
    .PARAMETER ASLogDrive
        String. Location for the log files of AS
    .PARAMETER ASTempdbDrive
        String. Location for the tempDB files of AS
    .PARAMETER ASBackupDrive
        String. Location for the backup files of AS
    .PARAMETER ASServerMode
        String. The server mode for SQL Server Analysis Services instance. The default is to install in Multidimensional mode.
    .PARAMETER ASSvcAccount
        String. Service account to run the instance of AS
    .PARAMETER ASSVCpassword
        String. Service account password to run the instance of AS
    .PARAMETER AsSvcStartupType
        String. Startup type of the AS instance
    .PARAMETER ForceReboot
        Boolean. Commands server to restart OS
    
    .EXAMPLE
    Install IS feature with service accounts
    Set-SqlDscFeatureAnalysisServices -SQLSetupPath "Z:\" -ISSvcAccount 'adsql\sql' -ISSVCpassword '!@YHFNW@'
#>

function Set-SqlDscFeatureAnalysisServices
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLSetupPath,

        [Parameter()]
        [System.String]
        $InstanceName,
        
        [Parameter()]
        [System.String]
        $ASCollation,

        [Parameter()]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter()]
        [System.String]
        $ASConfigDir,

        [Parameter()]
        [System.String]
        $ASDataDrive,


        [Parameter()]
        [System.String]
        $ASLogDrive,

        [Parameter()]
        [System.String]
        $ASTempdbDrive,

        [Parameter()]
        [System.String]
        $ASBackupDrive,

        [Parameter()]
        [ValidateSet("MULTIDIMENSIONAL","TABULAR","POWERPIVOT")]
        [System.String]
        $ASServerMode,

        [Parameter()]
        [System.String]
        $ASSvcAccount,

        [Parameter()]
        [System.String]
        $ASSVCpassword,

        [Parameter()]
        [ValidateSet("Automatic","Disabled","Manual")]
        [System.String]
        $AsSvcStartupType,

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

        If(!$ASDataDrive) {
            $ASDataDrive  = 'E:\MSSQL'
        }

        If(!$ASLogDrive) {
            $ASLogDrive  = 'F:\MSSQL'
        }

        If(!$ASTempdbDrive) {
            $ASTempdbDrive  = 'G:\MSSQL'
        }

        If(!$ASBackupDrive) {
            $ASBackupDrive  = 'H:\MSSQL'
        }

        #set Server mode if not provided
        If (!$ASServerMode) {
            $ASServerMode = 'MULTIDIMENSIONAL'
        }
        
        #Set SQL DSC install parameters
            $sqlSetupParams = @{
                SourcePath             = $SQLSetupPath
                InstanceName           = $InstanceName
                Features               = 'AS'
                ASSysAdminAccounts     = $ASSysAdminAccounts
                ASDataDir              = (Join-Path $ASDataDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\DATA")
                ASLogDir               = (Join-Path $ASLogDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\LOG")
                ASBackupDir            = (Join-Path $ASBackupDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\BACKUP")
                ASTempDir              = (Join-Path $ASTempdbDrive "MSSQL$SQLMajorVersion.$InstanceName\MSSQL\TEMPDB")
                ASServerMode           = $ASServerMode
        }

        #set IS service accounts
        If($ASSvcAccount -and $ASSVCpassword) {
            $SVCPass = ConvertTo-SecureString -String "$ASSVCpassword" -AsPlainText -Force
            $SVCpsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($ASSvcAccount, $SVCPass)
            $sqlSetupParams.Add('ASSvcAccount',$SVCpsCred)
        }

        #set reboot
        If ($ForceReboot -eq $true) { 
            $sqlSetupParams.Add('ForceReboot',$ForceReboot) 
        }

        #set startup type
        If (!$AsSvcStartupType) {
            $sqlSetupParams.Add('AsSvcStartupType','Automatic')
        }
        Else {
            $sqlSetupParams.Add('AsSvcStartupType',$AsSvcStartupType)
        }

        #set AS Collation
        If($ASCollation) {
              $sqlSetupParams.Add('ASCollation', $ASCollation)
        }

        #set AS config directory
        If ($ASConfigDir) {
            $sqlSetupParams.Add('ASConfigDir', $ASConfigDir)
        }


        #install AS instance
        If ($SQLSetupPath) {
            $testSqlSetup = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Test -Verbose
            If (!$testSqlSetup) {
                Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Set -Verbose
                Write-Host 'Analysis Services has been installed successfully' -BackgroundColor DarkGreen -ForegroundColor White
            }
             
            Else {
            Write-Host 'Skipping setup. SQL Server Analysis Services already exists.' -BackgroundColor DarkGreen -ForegroundColor Yellow
            } 
        }
        
        Else {
            Write-Host 'Skipping setup. No setup path provided.' -BackgroundColor Yellow -ForegroundColor Black
        }
    } 
     
    Catch{
        Write-Error "Error. Please check your command string: $_"
    }


}