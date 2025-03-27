<#
    .SYNOPSIS
        Hides instance from network.
    .DESCRIPTION 
        Sets the instance to be visible or hidden from the network. only works locally.
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER EnableHideInstance
        Boolean. Determines whether hiding of instance is enabled or not.
    
    .EXAMPLE

#>

function Set-SqlDscHideInstance
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [ValidateNotNull()]
        [System.Boolean]
        $EnableHideInstance
    )
    try {
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

        If(!$EnableHideInstance) {
            $EnableHideInstance = $false
        }



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
    Catch {
        Write-Error "$_"
    }

}
