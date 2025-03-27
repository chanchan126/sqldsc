<#
    .SYNOPSIS
        Configures SQL Server memory
    .Description
        Sets SQL Server minimum and maximum memory configuration according to SQL standards. Values can be overridden when standards do not meet the requirements.
    .PARAMETER SqlServerName
        String. Contains the server/host to connect to.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER MinMemory
        Int64. Contains the minimum memory size in MB.
    .PARAMETER MaxMemory
        Int64. Contains the maximum memory size in MB. If no value provided, OS memory less 2GB will be implemented.
    .PARAMETER WindowsCred
        String. Use this in conjunction with WindowsPassword to login using Windows authentication.
    .PARAMETER WindowsPassword
        String. Use this in conjunction with WindowsCred to login using Windows authentication.
    .PARAMETER WindowsPSCredential
        PSCredential. Use this to be prompted to enter username and password (instead of using WindowsCred and WindowsPassword).
    .PARAMETER RestartService
        Boolean. Determines whether the instance should be restarted
    
            
    .EXAMPLE
        Connect to named instance with 128MB of min memory and 2048MB of max memory
        Set-SqlDscMemory -InstanceName 'INSTNAME' -MinMemory 128 -MaxMemory 2048
        
        Connect to default instance with 1024 of minimum MB and OS Memory less 2GB for the max memory
        Set-SqlDscMemory -MinMemory 1024
#>

function Set-SqlDscMemory
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
        [System.Int64]
        $MinMemory,

        [Parameter()]
        [System.Int64]
        $MaxMemory,

        [Parameter()]
        [System.String]
        $WindowsCred, # Needs to be refactored (perhaps with parameter set) to only allow $WindowsCred OR $WindowsPSCredential)

        [Parameter()]
        [System.String]
        $WindowsPassword, # Needs to be refactored (perhaps with parameter set) to only allow $WindowsCred OR $WindowsPSCredential)

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $WindowsPSCredential, # Needs to be refactored (perhaps with parameter set) to only allow $WindowsCred OR $WindowsPSCredential)

        [Parameter()]
        [System.Boolean]
        $RestartService

    )
    try {
        $ErrorActionPreference = 'Stop'
        
        #Default value for server/host
        If(!$SqlServerName -or $SqlServerName -eq '') {
            $SqlServerName = $env:COMPUTERNAME
        }

        #Default value for instance name 
        If(!$InstanceName -or $InstanceName -eq '') {
            $InstanceName = 'MSSQLSERVER'
        }

        #Stop if MinMem is greater that MaxMem
        If ($MinMemory -gt $MaxMemory) {
            Write-Error "Mininum Memory is greater that Maxinum Memory. Please check your values again"
        }

        #Set Min SQL Memory if not provided
        If (!$MinMemory) {
            $MinMemory = 1024
        }
        
        #Set Min SQL Memory
        $minmem = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "min server memory (MB)"
            OptionValue = $MinMemory
        }

        #Set Max SQL Memory if not provided
        If (!$MaxMemory -or $MaxMemory -le 1023) {
        [int64]$OSMemoryRetention = 2GB
        [int64]$MaxMemory = (((Get-WmiObject  -ClassName 'Cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum)-$OSMemoryRetention) /1MB
        $MaxMemory
        }

        #Set Max SQL Memory
        $maxmem = @{
            ServerName = $SqlServerName
            InstanceName = $InstanceName
            OptionName = "max server memory (MB)"
            OptionValue = $MaxMemory
        }

        If ($RestartService -eq $true){
            $maxmem.Add('RestartService', $RestartService)
        }
        
        If ($WindowsCred) { # Needs to be refactored (perhaps with parameter set) to only allow $WindowsCred OR $WindowsPSCredential)
        $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
        $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
        $minmem.Add('PsDscRunAsCredential', $WindowsPSCred)
        $maxmem.Add('PsDscRunAsCredential', $WindowsPSCred)
        }

        If ($WindowsPSCredential) { # Needs to be refactored (perhaps with parameter set) to only allow $WindowsCred OR $WindowsPSCredential)
            $minmem.Add('PsDscRunAsCredential', $WindowsPSCredential)
            $maxmem.Add('PsDscRunAsCredential', $WindowsPSCredential)
        }

        $TestMinMem = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $minmem -Method Test -Verbose
        $TestMaxMem = Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $maxmem -Method Test -Verbose
        
        If ($TestMinMem) { Write-Host "Mininum memory value is already set" -BackgroundColor DarkMagenta -ForegroundColor White }
        If ($TestMaxMem) { Write-Host "Maximum memory value is already set" -BackgroundColor DarkMagenta -ForegroundColor White }

        If (!$TestMinMem) {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $minmem -Method Set -Verbose
            Write-Host "Minimum memory is set to $MinMemory MB " -BackgroundColor DarkGreen -ForegroundColor White
        }
        If (!$TestMaxMem) {
            Invoke-DscResource -ModuleName SqlServerDsc -Name SqlServerConfiguration -Property $maxmem -Method Set -Verbose
            Write-Host "Maximum memory is set to $MaxMemory MB " -BackgroundColor DarkGreen -ForegroundColor White
        }

    }
    Catch { 
        Write-Error "$_" }
       
}