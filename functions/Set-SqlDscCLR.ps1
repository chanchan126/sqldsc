<#
    .SYNOPSIS
        Configuration option for SQL Server CLR 
    .Description
        Sets the SQL Server CLR configuration to be enabled or disabled
    .PARAMETER SqlServerName
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER IsEnabled
        Boolean. Determines whether the option is enabled or disabled
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        Boolean. Determines the instance restart
    
    .EXAMPLE
    Set-SqlDscCLR -isEnabled 1

#>

function Set-SqlDscCLR
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
    try {
        
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        If ($isEnabled -eq $true){
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
        
        If ($RestartService -eq $true){
            $clr.Add('RestartService', $RestartService)
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
        Write-Error "$_" 
    }
       
}