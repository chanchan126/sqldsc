<#
    .SYNOPSIS
        SQL Server Management Studio installation
    .Description
        Sets the target server to install SQL Server Management Studio. only works with local install
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
    Install SSMS
    Set-SqlDscInstallSSMS -SSMSPackage 'C:\SQLServerInstallation\PreReqs\SSMS-Setup-ENU.exe' -SSMSProductId '7871DA56-98B6-4EF8-B4D4-B7C310E14146'
    
#>

function Set-SqlDscInstallSSMS
{
    [CmdletBinding()]
    param
    (
        #[Parameter()]
        #[System.String]
        #$SqlServerName = $env:COMPUTERNAME,

        #[Parameter()]
        #[System.String]
        #$InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.String]
        $SSMSPackage = 'C:\SQLServerInstallation\PreReqs\SSMS-Setup-ENU.exe',

        [Parameter()]
        [System.String]
        $SSMSProductId = '7871DA56-98B6-4EF8-B4D4-B7C310E14146'

    )
    try {

        #Install SSMS
        $SSMSParams = @{
            Name      = 'SSMS-Setup-ENU'
            Ensure    = 'Present'
            Path      = $SSMSPackage
            Arguments = '/install /passive /norestart'
            ProductId = $SSMSProductId
        }

        If ($SSMSPackage) {
            $testSSMS = Invoke-DscResource -ModuleName @{ModuleName='PSDesiredStateConfiguration'; ModuleVersion='1.1'} -Name Package -Property $SSMSParams -Method Test

            If (!$testSSMS) {
                Write-Host 'Installing(SSMS)...' -BackgroundColor White -ForegroundColor Black
                Invoke-DscResource -ModuleName @{ModuleName='PSDesiredStateConfiguration'; ModuleVersion='1.1'} -Name Package -Property $SSMSParams -Method Set -Verbose
            } 
        
            Else {
                Write-Host 'Skipping(SSMS)... Package already installed.' -BackgroundColor Yellow -ForegroundColor Black
            }

        } 
    
        Else {
            Write-Host 'Skipping(SSMS)... No package provided.' -BackgroundColor Yellow -ForegroundColor Black
        }
    }
    
    Catch { 
        Write-Error "$_" }
       
}