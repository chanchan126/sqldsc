<#
    .SYNOPSIS
        Enable or Disable SQL Server backup compression
    .DESCRIPTION
        Sets the SQL Server backup compression to be enabled or disabled
    .PARAMETER SqlServerName
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER IsEnabled
        switch. Determines whether the option is enabled or disabled. By default, this is enabled
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        Boolean. Determines instance restart

    .EXAMPLE
        Enable backup compression on a named instance
        Set-SqlDscBackupCompression -InstanceName 'INSTNAME' 
#>

function Set-SqlDscBackupCompression
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
        [System.Boolean]
        $isEnabled,

        [Parameter()]
        [System.String]
        $WindowsCred,

        [Parameter()]
        [System.String]
        $WindowsPassword,

        [Parameter()]
        [System.Boolean]
        $RestartService

    )
    Try {
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }
        
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        If (!$isEnabled){
            $isEnabled = 1
        }
        

        #Enable Backup Compression
        $backup = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "backup compression default"
            OptionValue = $BackupCompression
            RestartService = $false
        }

        If ($WindowsCred) {
            $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
            $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
            $backup.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        $SQLTest = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $backup -Method Test -Verbose
        If ($SQLTest) {
            Write-Host "Backup compression is already set" -BackgroundColor DarkMagenta -ForegroundColor White
        }
        Else {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $backup -Method Set -Verbose
     
            If ($BackupCompression -eq 1){
                Write-Host "Backup compression is enabled." -BackgroundColor DarkGreen -ForegroundColor White
            }
            Else{
                Write-Host "Backup compression is disabled." -BackgroundColor Red -ForegroundColor White
            }
        }

        If ($RestartService -eq $true) {
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
    Catch {
        Write-Error "$_"
    }
}