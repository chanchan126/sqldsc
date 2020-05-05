﻿<#
    .SYNOPSIS
        configuration option for SQL Server MailXPs 
    .Description
        Set configuration option value for MailXPs
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
        
#>

function Set-SqlDscDisableMailXPs
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
    try {

        If ($isEnabled){
            $DBMailXPvalue = 1
        }
        Else {
            $DBMailXPvalue = 0
        }
         
        If ($RestartService){
            [boolean]$RestartServ = 1
            $clr.Add('RestartService', $RestartServ)
        }       
        
        #Disable Database Mail XPs
        $dbmail = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "Database Mail XPs"
            OptionValue = $DBMailXPvalue
        }

        If ($RestartService){
            [boolean]$RestartServ = 1
            $dbmail.Add('RestartService', $RestartServ)
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
     
            If ($DBMailXP -eq 1){
                Write-Host " is enabled. Please refer to SQL CIS for more information on security" -BackgroundColor Red -ForegroundColor White
            }
            Else{
                Write-Host "DBMailXP is disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }

    }
    Catch { 
        Write-Error "$_" }
       
}