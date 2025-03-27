<#
    sqldsc.psm1 is a simplified automation for configurations and tasks that will help DBA's increase productivity
    
    This module contains functions that are an essential for daily DBA tasks.

    #Import-Module dbatools
#>

Import-Module sqlserverdsc -Force -Verbose


$FunctionCollection = @(Get-ChildItem -Path $PSScriptRoot\functions\*.ps1)
$FunctionCollection | Unblock-File

foreach($import in $FunctionCollection) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $FunctionCollection.BaseName


