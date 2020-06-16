<#
    .SYNOPSIS
        Enable or Disable SQL Server backup compression
    .DESCRIPTION
        sets the SQL Server backup compression to be enabled or disabled
    .PARAMETER SqlServerName
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER IsEnabled
        switch to determine whether the option is enabled or disabled
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        switch to determine instance restart

    .EXAMPLE
        Enable backup compression
        Set-SqlDscBackupCompression -isEnabled 1
#>

function Set-SqlDscBackupCompression
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
        [switch]
        $isEnabled,

        [Parameter()]
        [System.String]
        $WindowsCred,

        [Parameter()]
        [System.String]
        $WindowsPassword,

        [Parameter()]
        [switch]
        $RestartService

    )
    Try {
        If(!$InstanceName -or $InstanceName -eq '') {
            $InstanceName = 'MSSQLSERVER'
        }

        If ($isEnabled){
            $BackupCompression = 1
        }
        Else {
            $BackupCompression = 0
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

        $Test = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $backup -Method Test -Verbose
        If ($Test) {
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

    }
    Catch {
        Write-Error "$_"
    }
}