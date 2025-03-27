<#
    .SYNOPSIS
        Configuration for SA account which can be renamed, enabled or disabled 
    .Description
        Sets SA account to be renamed, enabled or disabled
    .PARAMETER SqlServerName
        String. containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String. containing the SQL Server instance name.
    .PARAMETER isSADisabled
        Boolean. Determines whether the option is enabled or disabled. Default is enabled.
    .PARAMETER isSARenamed
        Boolean. Determines whether the option is renamed or not. Default is renamed ($true).
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        switch to determine instance restart
            
    .EXAMPLE
        Set-SqlDscSysAdmin -isSADisabled $true -isSARenamed $true
#>

function Set-SqlDscSysAdmin
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
        $isSADisabled,

        [Parameter()]
        [System.Boolean]
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
        
        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }
        
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        If(!$isSADisabled){
            $isSADisabled = $true
        }

        If(!$isSARenamed){
            $isSARenamed = $true
        }
        
        #Set ServerName for Invoke-Sqlcmd
        If (!$InstanceName -or $InstanceName -eq 'MSSQLSERVER'){
            $SQLInstance = $SqlServerName
        }
        Else{
            $SQLInstance = (Join-Path "$SqlServerName\" "$InstanceName")
        }       
        
        If($isSARenamed -eq $true){
            If ($isSADisabled -eq $true){
                $DisableSAQuery = "ALTER LOGIN [sa] WITH NAME = [SAaccount];ALTER LOGIN [SAaccount] DISABLE"
            }
    
            ElseIf($isSADisabled -eq $false){
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

            $Test = Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScriptQuery -Property $DisableSA -Method Get -Verbose
        
            If (!$Test) {
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