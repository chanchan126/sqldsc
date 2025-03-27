<#
    .SYNOPSIS
        DBAid Collector collects information from all the SQL Servers that is configured in its configuration file. This can be configured to send email to datacom mailbox for daily checks.
    .DESCRIPTION
        Sets the DBAid Collector on target server to collect information for SQL monitoring and daily checks
    .PARAMETER SQLServerName
        Install SQL Server default or named . If this is a clustered SQL instance, change this to $SqlServerName = "<VNN of SQL instance>"
    .PARAMETER InstanceName
        String. Name of the instance or instances. MSSQLSERVER is the default instance. If more than 1 instance, follow this pattern. 'INST1','INST2'
    .PARAMETER DBAidDBName
        String. Name of database to deploy dbaid to. "_dbaid" is the default DB Name
    .PARAMETER DBAidInstaller
        String. Root directory for DBAid install files
    .PARAMETER CollectorLocation
        String. Folder where to put SQL monitoring files for processing.
    .PARAMETER EmailEnable
        Boolean. Enable or disable emailing of monitoring files. Default is disabled
    .PAREMETER EmailSmtp
        String. SMTP server for client email
    .PARAMETER EmailTo
        String. email address to send sql monitoring files to. dnzsqlmon@datacom.co.nz is default
    .PARAMETER EmailFrom
        String. Who the collector files came from (usually <hostname|VNN@domain.co.nz)
    .PAREMETER CollectorServiceAccount
        String. Local or Domain account which will be used when creating the task scheduler
    .PARAMETER CollectorServiceAccountPassword
        String. Password for the CollectorServiceAccount
    .PARAMETER Scheduler
        String. Option if you want to create task scheduler or SQL job
    

    .EXAMPLE
        Set-SqlDscDBAidCollector -DBAidInstaller "C:\SQLServerInstallation\PreReqs\DBAid" -CollectorLocation "C:\Datacom" -EmailEnable 0 -CollectorServiceAccount "adsql\sql" -CollectorServiceAccountPassword "!Qaz2wsx" -Scheduler "Windows"
#>


function Set-SqlDscDBAidCollector
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
        $DBAidDBName,
        
        [Parameter()]
        [System.String]
        $DBAidInstaller,
        
        [Parameter()]
        [System.String]
        $CollectorLocation,
        
        [Parameter()]
        [System.Boolean]
        $EmailEnable,
        
        [Parameter()]
        [System.String]
        $EmailSmtp,
        
        [Parameter()]
        [System.String]
        $EmailTo,
        
        [Parameter()]
        [System.String]
        $EmailFrom,
        
        [Parameter()]
        [System.String]
        $CollectorServiceAccount,
        
        [Parameter()]
        [System.String]
        $CollectorServiceAccountPassword,
        
        [Parameter()]
        [System.String]
        $Scheduler

    )
    
    try {
        Write-Host "Deploying DBAid collector..." -BackgroundColor DarkGreen -ForegroundColor White    
        
        If(!$InstanceName) {
            $InstanceName = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
            If(!$InstanceName) {
                Write-Error "No SQL instance installed. Aborting."
            }
        }

        If(!$SqlServerName) {
            $SqlServerName = $env:COMPUTERNAME
        }

        If(!$DBAidDBName) {
            $DBAidDBName = '_dbaid'
        }
        
        If(!$EmailEnable) {
            $EmailEnable = $False
        }
        
        If(!$EmailTo) {
            $EmailTo = "dnzsqlmon@datacom.co.nz"
        }

        If (!$EmailFrom) {
            $EmailFrom = "customer@$SqlServerName.domain.co.nz"
        }

        If (!$Scheduler) {
            $Scheduler = "Windows"
        }

        #create directory if not existing
        If(!(Test-Path -Path $CollectorLocation)) {
             New-Item -ItemType Directory -Force -Path $CollectorLocation | Out-Null

                 
            $Acl = Get-Acl $CollectorLocation
            $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($CollectorServiceAccount,"Modify","ContainerInherit, ObjectInherit","None","Allow")))
            (Get-Item $CollectorLocation).SetAccessControl($Acl)

             write-host "Directory $CollectorLocation created" -BackgroundColor DarkGreen -ForegroundColor White
        }
        Else {
            write-host "Folder exists" -BackgroundColor DarkGreen -ForegroundColor White
        }

        # copy collector if not exists
        
        If(!(Test-Path -Path "$CollectorLocation\dbaid.collector.exe.config")) {
        
            #Copy collector files from installer
            Copy-Item "$DBAidInstaller\client\dbaid.collector*" $CollectorLocation -Recurse -Force
            $CollectorConfig =[xml](Get-Content "$CollectorLocation\dbaid.collector.exe.config" -Raw)
                    
            #remove defaults
            $CollectorConfig.configuration.connectionStrings.add | Where-Object { $_.name -imatch 'Hostname'} |ForEach-Object {$_.ParentNode.RemoveChild($_) } | Out-Null
            $CollectorConfig.Save("$CollectorLocation\dbaid.collector.exe.config")
            

            #Update Config with new entry

            ForEach ($Instance in $InstanceName) {
                If ($Instance -eq 'MSSQLSERVER') {
                    $SQLInstance = $SqlServerName
                    $connectionstring = "Server=$SqlServerName;Database=$DBAidDBName;Trusted_Connection=True;"
                }
                Else {
                    $SQLInstance = "$SqlServerName@$Instance"
                    $connectionstring = "Server=$SqlServerName\$Instance;Database=$DBAidDBName;Trusted_Connection=True;"

                }
                    $child = $CollectorConfig.CreateElement("add")
                    $child.SetAttribute("name",$SQLInstance)
                    $child.SetAttribute("connectionString", $connectionstring)
                    $CollectorConfig.configuration.connectionStrings.AppendChild($child) #| Out-Null
            }   
            $CollectorConfig.Save("$CollectorLocation\dbaid.collector.exe.config") 
        }
    
        Else {

           $CollectorConfig =[xml](Get-Content "$CollectorLocation\dbaid.collector.exe.config" -Raw)
           
           #remove deafults if still existing
           $CollectorConfig.configuration.connectionStrings.add | Where-Object { $_.name -imatch 'Hostname'} |ForEach-Object {$_.ParentNode.RemoveChild($_) } | Out-Null
           $CollectorConfig.Save("$CollectorLocation\dbaid.collector.exe.config")

           # edit existing file if exists
           ForEach ($Instance in $InstanceName) {
                If ($Instance -imatch 'MSSQLSERVER') {
                    $SQLInstance = $SqlServerName
                    $connectionstring = "Server=$SqlServerName;Database=$DBAidDBName;Trusted_Connection=True;"
                }
                Else {
                    $SQLInstance = "$SqlServerName@$Instance"
                    $connectionstring = "Server=$SqlServerName\$Instance;Database=$DBAidDBName;Trusted_Connection=True;"
                        
                }
                $child = $CollectorConfig.CreateElement("add")
                $child.SetAttribute("name",$SQLInstance)
                $child.SetAttribute("connectionString", $connectionstring)
                $CollectorConfig.configuration.connectionStrings.AppendChild($child)
            }
            $CollectorConfig.Save("$CollectorLocation\dbaid.collector.exe.config") 
        }

        # insert email settings
        # assuming these are going to be the same for each installation (this entire script run for each SQL instance)
        ForEach ($setting in $CollectorConfig.configuration.appSettings.add) {
            $setting_enable = $CollectorConfig.SelectSingleNode("/configuration/appSettings/add[@key='EmailEnable']")
            $setting_enable.SetAttribute("value", $EmailEnable)
            $setting_smtp = $CollectorConfig.SelectSingleNode("/configuration/appSettings/add[@key='EmailSmtp']")
            $setting_smtp.SetAttribute("value", $EmailSmtp)
            $setting_to = $CollectorConfig.SelectSingleNode("/configuration/appSettings/add[@key='EmailTo']")
            $setting_to.SetAttribute("value", $EmailTo)
            $setting_from = $CollectorConfig.SelectSingleNode("/configuration/appSettings/add[@key='EmailFrom']")
            $setting_from.SetAttribute("value", $EmailFrom)
        }

        # save changes to new config file
        $CollectorConfig.Save("$CollectorLocation\dbaid.collector.exe.config")


        #create scheduler
    
        $taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -ieq "DBAid Collector" }
    
        If($Scheduler -ieq "SQL") {

            $Assemblies="Microsoft.SqlServer.Smo"
            Foreach ($Assembly in $Assemblies) {
                $Assembly = [System.Reflection.Assembly]::LoadWithPartialName($Assembly)
            }

            $SQLserver = new-object ('Microsoft.SqlServer.Management.Smo.Server') $SqlServerName

            $SQLJob = New-Object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($SQLserver.JobServer, 'DBAid Collector')

            #Drop Job if existing
            $DropJob=$SQLserver.Jobserver.Jobs|where-object {$_.Name -like 'DBAid Collector'}
            If($DropJob){
                $DropJob=$SQLserver.Jobserver.Jobs|where-object {$_.Name -like 'DBAid Collector'}
                $DropJob.drop()
            }

            #create the job
            $SQLJob.Description = 'SQL monitoring'
            $SQLJob.Category = 'Data Collector'
            $SQLJob.OwnerLoginName = $CollectorServiceAccount
            $SQLJob.Create()

            #create the job step
            $SQLJobStep = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($SQLJob, 'run dbaid.collector.exe')
            $SQLJobStep.SubSystem = 'CMDExec'
            $SQLJobStep.Command = "$CollectorLocation\dbaid.collector.exe"
            $SQLJobStep.OnFailAction = 'QuitWithFailure'
            $SQLJobStep.Create()

            #start the job at step 1
            $SQLJobStepID = $SQLJobStep.ID
            $SQLJob.ApplyToTargetServer($SQLserver.Name)
            $SQLJob.StartStepID = $SQLJobStepID
            $SQLJob.Alter()

            #create job schedule
            $SQLJobSched = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($SQLJob, 'run schedule')
            $SQLJobSched.FrequencyInterval = 1
            $SQLJobSched.FrequencyTypes = 'Daily'
            $SQLJobSched.FrequencySubDayTypes = 'Once'
            $SQLJobSched.ActiveStartDate = get-date
            $TimeSpan = New-Object -TypeName TimeSpan -argumentlist 5, 0, 0 
            $SQLJobSched.ActiveStartTimeOfDay = $TimeSpan
            $SQLJobSched.IsEnabled = $true
            $SQLJobSched.Create()

            
        }

        ElseIf($Scheduler -ieq "Windows") {
            If($taskExists) {
            Write-Host "Scheduled Task is existing" -BackgroundColor DarkGreen -ForegroundColor Yellow
            }
            Else {
                $action = New-ScheduledTaskAction -Execute "$CollectorLocation\dbaid.collector.exe"
                $trigger =  New-ScheduledTaskTrigger -Daily -At 6am
                Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "DBAid Collector" -Description "Daily collection of SQL stats and errors" -User $CollectorServiceAccount -Password $CollectorServiceAccountPassword -RunLevel Limited |Out-Null
                Write-Host "Task Schedule has been created" -BackgroundColor DarkGreen -ForegroundColor White
            }
        }



    }
    catch {
      Write-Host "Some sort of terminating error deploying DBAid collector.
      $_"
      $Error
    }
}