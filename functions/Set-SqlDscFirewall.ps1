<#
    .SYNOPSIS
        Firewall port configuration to allow communication with the SQL Server 
    .DESCRIPTION
        Sets the Windows firewall to enable or disable SQL Server ports
    .PARAMETER SqlServerName
        String. Contains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER Features
        String. SQL services that need firewall enabled or disabled (SQLENGINE, IS, AS). Default is SQLENGINE
    .PARAMETER SourcePath
        String. Root location of the SQL install files (Used for instance installation)
    .PARAMETER Ensure
        String. enable or disable SQL firewall rules. Values should be either Present or Absent. Default is Enable/Present
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication

    .EXAMPLE
    Set-SqlDscFirewall -Features 'SQLENGINE' -Ensure Present
#>

function Set-SqlDscFirewall
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
        [System.String]
        $Features,

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
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If(!$InstanceNam) {
            $InstanceName = 'MSSQLSERVER'
        }
        
        If(!$Ensure) {
            $Ensure = 'Present'
        }

        If(!$Features) {
            $Features = 'SQLENGINE'
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