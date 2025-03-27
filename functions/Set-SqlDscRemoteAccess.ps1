<#
    .SYNOPSIS
        Configuration option for SQL Server Remote Access 
    .Description
        Sets Remote Access configuration option to be enabled or disabled.
    .PARAMETER SqlServerName
        String. containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String. containing the SQL Server instance name.
    .PARAMETER IsRemoteEnabled
        Boolean. Determines whether the option is enabled or disabled
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        Boolean. to determine instance restart
            
    .EXAMPLE
        Set-SqlDscRemoteAccess -IsRemoteEnabled 1
#>

function Set-SqlDscRemoteAccess
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
        $IsRemoteEnabled,

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

        If ($IsRemoteEnabled -eq $true){
            $RemoteAccessValue = 1
        }
        Else {
            $RemoteAccessValue = 0
        }
                            
        #Disable Remote Access
        $RemoteAccessDSC = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "Remote Access"
            OptionValue = $RemoteAccessValue
        }

        If ($RestartService -eq $true){
             $RemoteAccessDSC.Add('RestartService', $RestartService)
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
     
            If ($RemoteAccessValue -eq 1){
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