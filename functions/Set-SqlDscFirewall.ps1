<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER SqlServerName
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER Features
        String. Include here SQL services that need firewall enabled or disabled
    .PARAMETER SourcePath
        String. Root location of the SQL install files
    .PARAMETER Ensure
        String. create or remove SQL firewall rules. Values should be either Present or Absent. Default is Enable/Present
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication

#>

function Set-SqlDscFirewall
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
        [System.String]
        $Features = "SQLENGINE",

        [Parameter()]
        [System.String]
        $SourcePath,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.String]
        $WindowsCred,

        [Parameter()]
        [System.String]
        $WindowsPassword


    )
    try {
        
        If(!$InstanceName -or $InstanceName -eq '') {
            $InstanceName = 'MSSQLSERVER'
        }
        
        If(!$Ensure -or $Ensure -eq '') {
            $Ensure = 'Present'
        }

        #Enable firewall
        $firewallparam = @{
            Ensure       = $Ensure
            Features     = $Features
            InstanceName = $InstanceName
            SourcePath   = $SourcePath
        }

        If ($WindowsCred) {
            $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
            $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        }

        $Test = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlWindowsFirewall -Property $firewallparam -Method Test -Verbose

        If (!$Test) {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlWindowsFirewall -Property $firewallparam -Method Set -Verbose

        }
        Else {
            Write-Host "SQL advanced configuration options setting is already set" -BackgroundColor DarkGreen -ForegroundColor White
        }
    }
    Catch {
        Write-Error "$_"
    }    
}