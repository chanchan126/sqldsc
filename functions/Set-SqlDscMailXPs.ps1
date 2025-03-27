<#
    .SYNOPSIS
        Configuration option for enabling or disabling SQL Server MailXPs 
    .Description
        Sets configuration option value for MailXPs option
    .PARAMETER SqlServerName
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER IsMailXPEnabled
        Boolean. Determines whether the option is enabled or disabled
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        Boolean. Determines whether to restart the SQL instance service
            
    .EXAMPLE
     Enable MailXPs 
     Set-SqlDscMailXPs -IsMailXPEnabled 1
#>

function Set-SqlDscMailXPs
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
        $IsMailXPEnabled,

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
    try {
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }
        
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }
        
        If (!$IsMailXPEnabled){
            $IsMailXPEnabled = 0
        }
         
        If ($RestartService -eq $true){
            $dbmail.Add('RestartService', $RestartService)
        }       
        
        #DSC Database Mail XPs
        $dbmail = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "Database Mail XPs"
            OptionValue = $IsMailXPEnabled
        }

        If ($WindowsCred) {
        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        $dbmail.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        $Test = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $dbmail -Method Test -Verbose
        
        If ($Test) {
            Write-Host "DBMailXPs is already set" -BackgroundColor DarkMagenta -ForegroundColor White
        }
        Else {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $dbmail -Method Set -Verbose
     
            If ($DBMailXPvalue -eq 1){
                Write-Host "DBMailXP is enabled. Please refer to SQL CIS for more information on security" -BackgroundColor Red -ForegroundColor White
            }
            Else{
                Write-Host "DBMailXP is disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }

    }
    Catch { 
        Write-Error "$_" }
       
}