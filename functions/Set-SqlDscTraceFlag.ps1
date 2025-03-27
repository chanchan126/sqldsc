<#
    .SYNOPSIS
        SQL Server instance configuration for setting trace flags
    .DESCRIPTION
        Sets trace flag for a SQL Server instance 
    .PARAMETER InstanceName
        String. Contains the SQL Server instance name.
    .PARAMETER StartupParameter
        Hash String. Trace flag value which will be added in the SQL Service startup. default is '-T3226'. comma separated if adding more '-T1234','-T5678', etc
    
    .EXAMPLE
        Set trace flag
        Set-SqlDscTraceFlag -InstanceName 'INSTNAME' -StartupParameters '-T3288','-T4435'
#>

function Set-SqlDscTraceFlag
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.String[]]
        $StartupParameters
    )
    try {
        If(!$InstanceName) {
            $InstanceName = 'MSSQLSERVER'
        }

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
    Catch {
        Write-Error "$_"
    }    
}
