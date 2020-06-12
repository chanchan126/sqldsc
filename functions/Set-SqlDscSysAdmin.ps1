<#
    .SYNOPSIS
        configuration option for SQL Server CLR 
    .Description
        Set configuration option value for CLR
    .PARAMETER SqlServerName
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER isSADisabled
        switch to determine whether the option is enabled or disabled
    .PARAMETER isSARenamed
        switch to determine whether the option is renamed or not
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        switch to determine instance restart
            
    .EXAMPLE
        
#>

function Set-SqlDscSysAdmin
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
        $isSADisabled,

        [Parameter()]
        [switch]
        $isSARenamed,

        [Parameter()]
        [System.String]
        $WindowsCred,

        [Parameter()]
        [System.String]
        $WindowsPassword
    )

    try {
        $ErrorActionPreference = 'Stop'
        
        If(!$InstanceName -or $InstanceName -eq '') {
            $InstanceName = 'MSSQLSERVER'
        }
        
        #Set ServerName for Invoke-Sqlcmd
        If (!$InstanceName){
            $SQLInstance = $SqlServerName
        }
        Else{
            $SQLInstance = (Join-Path "$SqlServerName\" "$InstanceName")
        }       
        
        If($isSARenamed){
            If ($isSADisabled){
                $DisableSAQuery = "ALTER LOGIN [sa] WITH NAME = [SAaccount];ALTER LOGIN [SAaccount] DISABLE"
            }
    
            ElseIf($disabledSA -eq $false){
                $DisableSAQuery = "ALTER LOGIN [sa] WITH NAME = [SAaccount]"
            }

            $checkSAQuery = "select * from sys.sql_logins where name = 'sa' and is_disabled = 0"

            $DisableSA = @{
                ServerInstance = $SQLInstance
                SetQuery = $DisableSAQuery
                TestQuery = $DisableSAQuery
                GetQuery = $checkSAQuery
                QueryTimeout = 20
            }  

            If ($WindowsCred) {
                $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
                $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
                $DisableSA.Add('PsDscRunAsCredential', $WindowsPSCred)
            }

            $checkSAExists = Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $DisableSA -Method Get -Verbose
        
            If ($checkSAExists -eq '') {
                Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $DisableSA -Method Set -Verbose
                Write-Host "SA has been renamed and disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
            
            Else{
                Write-Host "SA already renamed and/or disabled" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }
    }
  
    Catch { 
        Write-Error "$_" }
       
}