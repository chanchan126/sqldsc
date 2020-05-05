<#
    .SYNOPSIS
        configuration option for SQL Server CLR 
    .Description
        Set configuration option value for CLR
    .PARAMETER SqlServerName
        String containing the SQL Server to connect to.
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER MinMemory
        int64 containing the minimum memory size in MB
    .PARAMETER MaxMemory
        int64 containing the maximum memory size in MB. if no value provided, OS memory - 2GB will be implemented.
    .PARAMETER WindowsCred
        String. Use this to login using Windows authentication
    .PARAMETER WindowsPassword
        String. Use this to login using Windows authentication
    .PARAMETER RestartService
        switch to determine instance restart
            
    .EXAMPLE
        connect to named instance with 128MB of min memory and 2048 or max memory
        Set-SqlDscMemory -InstanceName 'CHAN' -MinMemory 128 -MaxMemory 2048
        
        Connect to default instance with 1024 of minimum mb and OS Memory -2GB for the max memory
        Set-SqlDscMemory -MinMemory 1024
#>

function Set-SqlDscMemory
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
        [System.Int64]
        $MinMemory,

        [Parameter()]
        [System.Int64]
        $MaxMemory,

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

                
        #Set Min SQL Memory
        $minmem = @{
            ServerName = $Hostname
            InstanceName = $InstanceName
            OptionName = "min server memory (MB)"
            OptionValue = $MinMemory
        }

        #Set Max SQL Memory if not provided
        If (!$MaxMemory) {
        [int64]$OSMemoryRetention = 2GB
        [int64]$MaxMemory = (((Get-WmiObject  -ClassName 'Cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum)-$OSMemoryRetention) /1MB
        $MaxMemory
        }

        $maxmem = @{
            ServerName = $Hostname
            InstanceName = $InstanceName
            OptionName = "max server memory (MB)"
            OptionValue = $MaxMemory
        }

        Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $maxmem -Method Set -Verbose
        
        If ($RestartService){
            [boolean]$RestartServ = 1
            maxmem.Add('RestartService', $RestartServ)
        }
        
        If ($WindowsCred) {
        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        $minmem.Add('PsDscRunAsCredential', $WindowsPSCred)
        $maxmem.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        $TestMinMem = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $minmem -Method Test -Verbose
        $TestMaxMem = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $maxmem -Method Test -Verbose
        
        If ($TestMinMem) { Write-Host "Mininum memory value is already set" -BackgroundColor DarkMagenta -ForegroundColor White }
        #If ($TestMaxMem) { Write-Host "Maximum memory value is already set" -BackgroundColor DarkMagenta -ForegroundColor White }

        If (!$TestMinMem) {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $minmem -Method Set -Verbose
            Write-Host "Minimum memory is set to $MinMemory MB " -BackgroundColor DarkGreen -ForegroundColor White
        }
        #If (!$TestMaxMem) {
        #    Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $maxmem -Method Set -Verbose
            Write-Host "Maximum memory is set to $MaxMemory MB " -BackgroundColor DarkGreen -ForegroundColor White
        #}

    }
    Catch { 
        Write-Error "$_" }
       
}