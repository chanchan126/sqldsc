<#
    .SYNOPSIS
        configuration option for SQL Server Remote Access 
    .Description
        Set configuration option value for Remote Access
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

function Set-SqlDscRemoteAccess
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
            $RemoteAccess = 1
        }
        Else {
            $RemoteAccess = 0
        }
                    
        #Disable Remote Access
        $RemoteAccessDSC = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "Remote Access"
            OptionValue = $RemoteAccess
        }

        If ($RestartService){
            [boolean]$RestartServ = 1
            $RemoteAccessDSC.Add('RestartService', $RestartServ)
        }     

        If ($WindowsCred) {
        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        $RemoteAccessDSC.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        $Test = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $RemoteAccessDSC -Method Test -Verbose
        
        If ($Test) {
            Write-Host "Remote Access is already set" -BackgroundColor DarkMagenta -ForegroundColor White
        }
        Else {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $RemoteAccessDSC -Method Set -Verbose
     
            If ($RemoteAccess -eq 1){
                Write-Host "RemoteAccess is enabled. Please refer to SQL CIS for more information on security" -BackgroundColor Red -ForegroundColor White
            }
            Else{
                Write-Host "RemoteAccess is disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }
    }
    Catch { 
        Write-Error "$_" 
    }
       
}