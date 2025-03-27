<#
    .SYNOPSIS
        DBAid Client for SQL monitoring and daily error checking 
    .DESCRIPTION
        Sets the DBAid client for SQL monitoring
    .PARAMETER SqlServerName
        String. Name of the server
    .PARAMETER InstanceName
        Hash String. contains 1 or more instances. Default is to include all instances installed on the server.
    .PARAMETER ConfigGDirectoryName
        String. Name for the config genie directory. Defualt name is Datacom
    .PARAMETER DBAidLocation
        String. DBAid root directory location
    .PARAMETER SourceCheckMK
        String. Root Check_MK install directory. Location needs to be where the local subfolder is placed. Default will detect the default install location of Check_MK
    .PARAMETER ClientDomain
        String. Client's domain name. Must start with @ sign
    .PARAMETER PublicKey
        String. Public key to use for DBAid authentication. value should be like this <RSAKeyValue><Modulus>10391GCVAE0293JKIHASKJB</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>
    .PAREMETER CollectorServiceAccount
        String. Local or Domain account which will be used to access stats collection of SQL instance and databases. NT AUTHORITY\SYSTEM is the default value
    .PARAMETER CheckServiceAccount
        String. Check_MK service account that will used to access stats collection of SQL instance and databases.  NT AUTHORITY\SYSTEM is the default value
    .PARAMETER WindowsCred
        String.Windows account to access SQL instance
    .PARAMETER WindowsCred
        String.Windows password to access SQL instance

    .EXAMPLE
        Set-SqlDscDBAid -ConfigGDirectoryName "C:\Datacom" -SourceDirectory "C:\SQLServerInstallation\PreReqs" -ClientDomain "@TEST.ALABS" -PublicKey "<RSAKeyValue><Modulus>10391GCVAE0293JKIHASKJB</Modulus><Exponent>AQAB</Exponent></RSAKeyValue>" -WindowsCred "adsql\sql" -WindowsPassword "&^$GQNBC"

#>

function Set-SqlDscDBAidClient
{
    [CmdletBinding()]
    param
    (
        
        [Parameter()]
        [System.String]
        $SqlServerName,

        [Parameter()]
        [System.String[]]
        $InstanceName,

        [Parameter()]
        [System.String]
        $ConfigGDirectory,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $DBAidLocation,

        [Parameter()]
        [System.String]
        $SourceCheckMK,
        
        [Parameter()]
        [System.String]
        $ClientDomain,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $PublicKey,
        
        [Parameter()]
        [System.String]
        $CollectorServiceAccount,
        
        [Parameter()]
        [System.String]
        $CheckServiceAccount,
        
        [Parameter()]
        [System.String]
        $WindowsCred,
        
        [Parameter()]
        [System.String]
        $WindowsPassword
    )

    Try {
        $ErrorActionPreference = "Stop"
        
        If (!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If (!$InstanceName) {
            $InstanceName = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
            If (!$InstanceName) {
                Write-Error "No SQL instance installed. Aborting."
            }
        }

        If (!$ConfigGDirectory) {
            $ConfigGDirectory = "C:\Datacom"
        }

        If(!$CollectorServiceAccount) {
            $CollectorServiceAccount = "NT AUTHORITY\SYSTEM"
        }

        If(!$CheckServiceAccount) {
            $CheckServiceAccount = "NT AUTHORITY\SYSTEM"
        }

        If ($ConfigGDirectory) {

            #create Datacom folder on C:\ if existing
            If (test-path -Path $ConfigGDirectory) {
                Write-Host "Directory $ConfigGDirectory already created" -BackgroundColor DarkGreen -ForegroundColor White
            }
            Else {
                New-Item -Path $ConfigGDirectory -ItemType "directory"
                Write-host "$ConfigGDirectory directory has been created" -BackgroundColor DarkGreen -ForegroundColor White
            }
 
            #copy config genie files to directory

            $testdbaidconfigg = Get-ChildItem -Path "$ConfigGDirectory" |Where-Object { $_.Name -like "dbaid.configg*" }  |Select-Object -expand name
            If (!$testdbaidconfigg) {
                Copy-Item -Path "$DBAidLocation\client\dbaid.configg*" -Destination $ConfigGDirectory
                Write-Host "Copied Config Genie files to $ConfigGDirectory" -BackgroundColor DarkGreen -ForegroundColor White
            }
            Else {
                Write-Host "Config Genie files are already existing" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }
        Else {
            Write-Host "No provided location for Config Genie. Skipping." -BackgroundColor DarkGreen -ForegroundColor Yellow
        }

        #Copy DBAid Check_MK files
        $CheckMKApp = Get-WmiObject Win32_Product | Where-Object { $_.Name -imatch "Check(.*?)MK"} | Select-Object Name,Version
        [decimal]$CheckMKversion = ($CheckMKApp.Version).Substring(0,3)
        Write-Host "Check_MK version is $CheckMKversion" -BackgroundColor DarkGreen -ForegroundColor Cyan

        If ($CheckMKversion -lt 1.6 -and !$SourceCheckMK) {
            $SourceCheckMK = "C:\Program Files (x86)\check_mk"
            Copy-Item -Path "$DBAidLocation\Client\dbaid.checkmk*" -Destination "$SourceCheckMK\local" -Force
            Write-Host "Check MK files copied successfully" -BackgroundColor DarkGreen -ForegroundColor White

            $CheckMKConfigFile = "$SourceCheckMK\local\dbaid.checkmk.exe.config"

        }
        ElseIf ($CheckMKversion -ge 1.6 -and !$SourceCheckMK) {
            $SourceCheckMK = "C:\ProgramData\checkmk\agent"
            Copy-Item -Path "$DBAidLocation\Client\dbaid.checkmk*" -Destination "$SourceCheckMK\local" -Force
            Write-Host "Check MK files copied successfully" -BackgroundColor DarkGreen -ForegroundColor White 
            
            $CheckMKConfigFile = "$SourceCheckMK\local\dbaid.checkmk.exe.config"
                 
        }
        ElseIf ($CheckMKversion -lt 1.6 -or $CheckMKversion -ge 1.6 -and $SourceCheckMK) {
            Copy-Item -Path "$DBAidLocation\Client\dbaid.checkmk*" -Destination "$SourceCheckMK\local" -Force
            Write-Host "Check MK files copied successfully" -BackgroundColor DarkGreen -ForegroundColor White

            $CheckMKConfigFile = "$SourceCheckMK\local\dbaid.checkmk.exe.config"
        }

        
        #Modify the Check_MK DBAid Config File
        
        $checkmkconfigcontents = Get-Content $CheckMKConfigFile

        $SqlServerName = $env:COMPUTERNAME
        $NewContent = @()

        #Remove DBAid check_mk sample lines
        $NewContentsCheckMK = $checkmkconfigcontents | Where-Object { $_ -notmatch "Trusted_Connection" }

        #Add new lines for all available instances
        foreach ($NewCheckMK in $NewContentsCheckMK) {
            $Match = '<clear />'
            $NewContent += $NewCheckMK
            If ($NewCheckMK -match $Match) {
                ForEach ($instance in $InstanceNames) {
                    $NewLine = '    <add name="' + $instance + '" connectionString="Server=' + $SqlServerName + ';Database=_dbaid;Trusted_Connection=True;" />' 
                    $NewContent += $NewLine
                }
            }
        }
        Set-Content $CheckMKConfigFile $NewContent
        Write-Host "Updated checkmk config file" -BackgroundColor DarkGreen -ForegroundColor White    
        
        
        # Update check_mk ini file
        $CheckMkIni = "[global]
    port = 6556
    sections = check_mk winperf local df ps mem services systemtime uptime

[winperf]
    counters = System:dc_system
    counters = Memory:dc_memory
    counters = Processor:dc_processor
    counters = Paging File:dc_pagefile
    #counters = VM Processor:dc_vmprocessor
    #counters = VM Memory:dc_vmmemory

[logfiles]
	
[logwatch]

[mrpe]

[fileinfo]

[local]

[plugins]
"

        If ($CheckMKversion -lt 1.6) {
            $CheckMkIniFile = "$SourceCheckMK\check_mk.ini"
            $TestcheckMkIniFile = Get-ChildItem -Path "$SourceCheckMK" |Where-Object {$_.Name -like 'check_mk.ini'} |Select-Object -expand name
            If($TestcheckMkIniFile) {
                Remove-Item $CheckMkIniFile
                Add-Content $CheckMkIniFile $CheckMkIni
                Write-Host "Check_MK ini file has been updated" -BackgroundColor DarkGreen -ForegroundColor White
            }
            Else {
                Write-Host "Check_MK ini file is not found. Creating the file" -BackgroundColor DarkGreen -ForegroundColor Yellow
                Add-Content $CheckMkIniFile $CheckMkIni
                Write-Host "Check_MK ini file has been updated" -BackgroundColor DarkGreen -ForegroundColor White
            }

        }
        ElseIf($CheckMKversion -ge 1.6) {
            $CheckMKuserfile = "$SourceCheckMK\check_mk.user.yml"
            
            #backup the file or restore the file
            if(Test-path -Path "$SourceCheckMK\check_mk.user.yml.BACKUP") {
                Copy-Item "$SourceCheckMK\check_mk.user.yml" "$SourceCheckMK\check_mk.user.yml.OLD" -Force
                Copy-Item "$SourceCheckMK\check_mk.user.yml.BACKUP" "$SourceCheckMK\check_mk.user.yml" -Force
            }
            Else {
                Copy-Item "$SourceCheckMK\check_mk.user.yml" "$SourceCheckMK\check_mk.user.yml.BACKUP" -Force
            }

            $EnableWinPerf = "    enabled: yes"
            $EnableLocal = "    enabled: yes"
            $EnableCounters = "        - System:dc_system
        - Memory:dc_memory
        - Processor:dc_processor
        - Paging File:dc_pagefile"

            # If check_mk user file is updated, check the index numbers again and update this
            $oldWinPerf = Get-Content $CheckMKuserfile | Select-Object -Index 163
            $oldLocal =  Get-Content $CheckMKuserfile | Select-Object -Index 270
            $oldCounter = Get-Content $CheckMKuserfile | Select-Object -Index 178

            (Get-Content $CheckMKuserfile).Replace($oldWinPerf, $EnableWinPerf) | Set-Content $CheckMKuserfile 
            (Get-Content $CheckMKuserfile).Replace($oldLocal, $EnableLocal) | Set-Content $CheckMKuserfile
            (Get-Content $CheckMKuserfile).Replace($oldCounter, $EnableCounters) | Set-Content $CheckMKuserfile
            Write-Host "Check_MK user file has been updated" -BackgroundColor DarkGreen -ForegroundColor white
        }
        Else {
            Write-Error "No Check_MK is installed. Exiting"
        }

  
        #Update DBAid SQL file
        $DBaidSQLFile = "$DBAidLocation\client\dbaid_release_create.sql"
                
        $NewClientDomainVar = ':setvar ClientDomain "' + $ClientDomain + '"'
        $NewPublicKeyVar = ':setvar PublicKey "' + $PublicKey + '"'
        $NewCollectorServiceAccountVar = ':setvar CollectorServiceAccount "' + $CollectorServiceAccount + '"'
        $NewCheckServiceAccountVar = ':setvar CheckServiceAccount "' + $CheckServiceAccount + '"'
                
        (Get-Content $DBaidSQLFile) -replace '^:setvar ClientDomain(.*)', $NewClientDomainVar | Set-Content $DBaidSQLFile
        (Get-Content $DBaidSQLFile) -replace '^:setvar PublicKey (.*)', $NewPublicKeyVar | Set-Content $DBaidSQLFile
        (Get-Content $DBaidSQLFile) -replace '^:setvar CollectorServiceAccount(.*)', $NewCollectorServiceAccountVar | Set-Content $DBaidSQLFile
        (Get-Content $DBaidSQLFile) -replace '^:setvar CheckServiceAccount(.*)', $NewCheckServiceAccountVar | Set-Content $DBaidSQLFile

        Write-Host "Updated DBAid SQL file " -BackgroundColor DarkGreen -ForegroundColor White

        #Execute DBAid SQL file

        foreach ($instance in $InstanceName) {
            If ($instance -match "MSSQLSERVER") {
                $SQLInstance = $SqlServerName
            }
            Else {
                $SQLInstance = (Join-Path "$SqlServerName\" "$instance")
            }   

            $DBAidQuery = @{
                ServerInstance  = $SQLInstance
                SetFilePath = $DBaidSQLFile
                GetFilePath = $DBaidSQLFile
                TestFilePath = $DBaidSQLFile
                QueryTimeout = 20
            } 

            If ($WindowsCred) {
                $WinPass = ConvertTo-SecureString "$WindowsPassword" -AsPlainText -Force
                $WindowsPSCred = New-Object System.Management.Automation.PSCredential -ArgumentList ($WindowsCred, $WinPass)
                $DBAidQuery.Add('PsDscRunAsCredential', $WindowsPSCred)
            }

            Invoke-DscResource -ModuleName SQLServerDSC -Name SqlScript -Property $DBAidQuery -Method Set
            Write-Host "DBAid has been installed on $SQLInstance" -BackgroundColor DarkGreen -ForegroundColor White 
       }
    }
    Catch {
        Write-Error "$_"
    }

}


