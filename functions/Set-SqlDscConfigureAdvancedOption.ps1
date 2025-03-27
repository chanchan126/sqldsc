<#
    .SYNOPSIS
        Enable or disabled Advanced Configuration Option 
    .Description
        Sets the advanced configuration option to be enabled or disabled
    .PARAMETER SqlServerName
        String. Constains the SQL Server to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER AdvancedOptionValue
        String. Default value is 0 (disabled).
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    
    .EXAMPLE
    Set-SqlDscConfigureAdvancedOption -AdvancedOptionValue 1 -WindowsCred 'adsql\sql' -WindowsPassword '123qwe'

#>

function Set-SqlDscConfigureAdvancedOption
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

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.String]
        $AdvancedOptionValue,

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

        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }
        
        If(!$AdvancedOptionValue) {
            $AdvancedOptionValue = '0'
        }
        

        #Set ServerName for Invoke-Sqlcmd
        If (!$InstanceName -or $InstanceName -eq 'MSSQLSERVER'){
            $SQLInstance = $SqlServerName
        }
        Else{
            $SQLInstance = (Join-Path "$SqlServerName\" "$InstanceName")
        }

        $SqlQuery = "sp_configure 'show advanced option', '$AdvancedOptionValue'; RECONFIGURE;"

        $SqlParam = @{
            ServerInstance = $SQLInstance
            SetQuery = $SqlQuery
            TestQuery = $SqlQuery
            GetQuery = $SqlQuery
            QueryTimeout = 20
        }  

        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        If ($WindowsCred){
            $SqlParam.Add('PsDscRunAsCredential',$WindowsPSCred)
        }
    
        If ($AdvancedOptionValue -eq '1') { 
            Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $SqlParam -Method Set -Verbose
            Write-Host "SQL advanced configuration options has been enabled" -BackgroundColor DarkGreen -ForegroundColor White 
        }
        Else {
            Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $SqlParam -Method Set -Verbose
            Write-Host "SQL advanced configuration options has been disabled" -BackgroundColor DarkGreen -ForegroundColor White 
        }
    }
 
    Catch {
        Write-Error "$_"
    }
}