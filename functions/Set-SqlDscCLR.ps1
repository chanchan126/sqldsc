<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
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

#>

function Set-SqlDscCLR
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
            $clrvalue = 1
        }
        Else {
            $clrvalue = 0
        }

        #Disable CLR
        $clr = @{
            ServerName = $Hostname
            InstanceName = $InstanceName
            OptionName = "clr enabled"
            OptionValue = $clrvalue
        }
        


        If ($RestartService){
            [boolean]$RestartServ = 1
            $clr.Add('RestartService', $RestartServ)
        }

        If ($WindowsCred) {
        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        $clr.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        $Test = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $clr -Method Test -Verbose
        
        If ($Test) {
            Write-Host "CLR value is already set" -BackgroundColor DarkMagenta -ForegroundColor White
        }
        Else {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $clr -Method Set -Verbose
     
            If ($clrvalue -eq 1){
                Write-Host "CLR is enabled. Please refer to SQL CIS for more information on security" -BackgroundColor Red -ForegroundColor White
            }
            Else {
                Write-Host "CLR is disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }

    }
    Catch { 
        Write-Error "$_" }
       
}