<#
    .SYNOPSIS
        SQL Server Management Studio installation. 
    .Description
        Sets the target server to install SQL Server Management Studio. only works with local install. Limited to install local only.
    .PARAMETER SSMSPackage
        String. Full path of the SSMS install file
    .PARAMETER SSMSProductId
        String. Product ID of the SSMS. Can be found by following the instructions from this site. https://gist.github.com/wsmelton/e2d9c6b2323d60d372d8192b24a24b0f

        SSMS needs to be used needs to be installed in a separate computer to get the Product ID. Then run the command below on PowerShell ISE to get the results.

        $x86Path = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $installedItemsX86 = Get-ItemProperty -Path $x86Path | Select-Object -Property DisplayName, PSChildName
        $x64Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $installedItemsX64 = Get-ItemProperty -Path $x64Path | Select-Object -Property DisplayName, PSChildName
        $installedItems = $installedItemsX86 + $installedItemsX64
        $installedItems | Where-Object -FilterScript { $_.DisplayName -like "Microsoft SQL Server Management Studio*" } | Sort-Object -Property DisplayName | fl

                
    .EXAMPLE
    Install SSMS
    Set-SqlDscInstallSSMS -SSMSPackage 'C:\SQLServerInstallation\PreReqs\SSMS-Setup-ENU.exe' -SSMSProductId '7871DA56-98B6-4EF8-B4D4-B7C310E14146'
    
#>

function Set-SqlDscInstallSSMS
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SSMSPackage,

        [Parameter()]
        [System.String]
        $SSMSProductId

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