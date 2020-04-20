<#
    .SYNOPSIS
        Set firewall ports to allow communication with the SQL Server 
    .PARAMETER InstanceName
        String containing the SQL Server instance name.
    .PARAMETER StartupParameter
        String Array. Trace flag value which will be added in the SQL Service startup. default is '-T3226'. comma separated if adding more '-T1234','-T5678', etc
    
#>

function Set-SqlDscTraceFlag
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName  = 'MSSQLSERVER',

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.String[]]
        $StartupParameters
    )

    $RegistryRoot = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.$InstanceName\MSSQLServer\Parameters"
    $RegistryProperties = Get-ItemProperty $RegistryRoot

    ForEach ($StartupValue in $StartupParameters) {
        
        $SQLArgParameters = $RegistryProperties.psobject.properties | Where-Object{$_.Name -like 'SQLArg*'} | Select-Object Name, Value

        If ($StartupValue -notin $SQLArgParameters.Value) {
            $newSQLArg = "SQLArg"+($SQLArgParameters.Count)
            
            Set-ItemProperty -Path $RegistryRoot -Name $newSQLArg -Value $StartupValue
            Write-Host "Successfully added $StartupValue" -BackgroundColor DarkGreen -ForegroundColor White
           
        } 
        Else {
            Write-Host "$StartupValue already set" -BackgroundColor DarkGreen -ForegroundColor White
        }
    }
}