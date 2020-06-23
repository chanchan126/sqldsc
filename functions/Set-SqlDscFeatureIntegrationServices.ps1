<#
    .SYNOPSIS
        SQL Server Integration Services feature installation. 
    .DESCRIPTION
        Sets target server to be installed with SQL Server Integration Services feature.
    .PARAMETER SQLSetupPath
        String containing the location of the setup exe file.
    .PARAMETER SQLInstanceName
        String containing the name of the instance. if value is blank, default instance will be installed. If 2 or more instances are in the same server, just choose 1 instance as it is a shared service.
    .PARAMETER ISSvcAccount
        String local or domain account for Integration Services 
    .PARAMETER ISSVCpassword
        String password for Integration Services account
    .PARAMETER ForceReboot
        Boolean. Commands server to restart OS
    
    .EXAMPLE
    Install IS feature with service accounts
    Set-SqlDscInstallFeatureIntegrationServices -SQLSetupPath "Z:\" -ISSvcAccount 'adsql\sql' -ISSVCpassword '!@YHFNW@'
#>

function Set-SqlDscFeatureIntegrationServices
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $SQLSetupPath,

        [Parameter()]
        [System.String]
        $SQLInstanceName,
        
        [Parameter()]
        [System.String]
        $ISSvcAccount,

        [Parameter()]
        [System.String]
        $ISSVCpassword,

        [Parameter()]
        [Boolean]
        $ForceReboot
    )

    try {
        $ErrorActionPreference = "Stop"
        
        #Set InstanceName variable if not provided
        If(!$SQLInstanceName) {
            $SQLInstanceName = 'MSSQLSERVER'
        }

        #Set SQL DSC install parameters
            $sqlSetupParams = @{
                SourcePath             = $SQLSetupPath
                InstanceName           = $SQLInstanceName
                Features               = 'IS'
        }

        #set IS service accounts
        If($ISSvcAccount -and $ISSVCpassword) {
            $SVCPass = ConvertTo-SecureString -String "$ISSVCpassword" -AsPlainText -Force
            $SVCpsCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($ISSvcAccount, $SVCPass)
            $sqlSetupParams.Add('ISSvcAccount',$SVCpsCred)
        }

        #set reboot
        If ($ForceReboot) { 
            $sqlSetupParams.Add('ForceReboot',$ForceReboot) 
        }

        #install sql instance
        If ($SQLSetupPath) {
            $testSqlSetup = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Test -Verbose
            If (!$testSqlSetup) {
                Invoke-DscResource -ModuleName SqlServerDsc -Name SqlSetup -Property $sqlSetupParams -Method Set -Verbose
                Write-Host 'Integration Services has been installed successfully' -BackgroundColor DarkGreen -ForegroundColor White
            }
             
            Else {
            Write-Host 'Skipping setup. Integration Services already exists.' -BackgroundColor DarkGreen -ForegroundColor Yellow
            } 
        }
        
        Else {
            Write-Host 'Skipping setup. No setup path provided.' -BackgroundColor Yellow -ForegroundColor Black
        }
    } 
     
    Catch{
        Write-Error "Error. Please check your command string: $_"
    }


}