<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER EnableHideInstance
        Switch. enabled 
    
#>

function Set-SqlDscHideInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNull()]
        [Switch]
        $EnableHideInstance = $false
    )

    
    $HidePropRoot = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.$InstanceName\MSSQLServer\SuperSocketNetLib"
    $HideProp = Get-ItemProperty -Path $HidePropRoot -Name 'HideInstance' | Select-Object -ExpandProperty HideInstance
    
    If ($EnableHideInstance -eq $true) {
        Set-ItemProperty -Path $HidePropRoot -Name 'HideInstance' -Value 1
        Write-Host "Hide instance is enabled" -BackgroundColor DarkGreen -ForegroundColor White
    }
    
    Else
    {
        Set-ItemProperty -Path $HidePropRoot -Name 'HideInstance' -Value 0
        Write-Host "Hide instance is disabled" -BackgroundColor DarkGreen -ForegroundColor White
    }
    

}
