<#
    sqldsc.psm1 is a simplified automation for configurations and tasks that will help DBA's increase productivity
    
    This module contains functions that are an essential for daily DBA tasks.
#>

Import-Module sqlserverdsc
Import-Module dbatools

$FunctionCollection = @(Get-ChildItem -Path $RootModule\functions\*.ps1 -ErrorAction SilentlyContinue)
$FunctionCollection | Unblock-File

foreach($import in $FunctionCollection) {
    try {
        . $import.fullname
    }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $FunctionCollection.Basename
