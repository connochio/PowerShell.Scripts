function Launch-Avid{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('NoLogging','Logging','LoggingAndUpload')]
        [String]$StartMode,
        [ValidateSet('Forced','Safe')]
        [String]$SiteSettings = "Safe",
        [Switch]$Debugging,
        [Switch]$SuperDebugging
        )
    
    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}
    
        # Set variables
    $hostname = $env:computername
    $username = $env:username
    $startTime = Get-Date

        # Set the site settings, based on the switch
    if($SiteSettings -eq "Safe"){set-avidsitesettings -safe}
    if($SiteSettings -eq "Forced"){set-avidsitesettings -Force}

        # If start specified, open Avid and wait for it to close
    if($StartMode -ne $null){
        $process = start-process "C:\Program Files\Avid\Avid Media Composer\AvidMediaComposer.exe" -PassThru
        $id = $process.Id
        do{start-sleep -s 10}
        until ((Get-Process -id $id) -eq $null)

            # If logging specified, run the log collection after process exits
        if(($StartMode -eq "Logging") -or ($StartMode -eq "LoggingAndUpload")){
            if($process.ExitCode -ne 0){
            
                    # Set deployment log folders
                $dep_zipDir = "C:\Deployment\Scripts\MediaComposer\Zips"
                $dep_baseDir = "C:\Deployment\Scripts\MediaComposer\Logs"
                $dep_fatalDir = "C:\Deployment\Scripts\MediaComposer\Logs\Fatal"
                $dep_logDir = "C:\Deployment\Scripts\MediaComposer\Logs\Logs"
                $dep_crashDir = "C:\Deployment\Scripts\MediaComposer\Logs\Crash"
            
                    # Set local log folders
                $loc_crashDir = "C:\Users\$username\AppData\Local\Avid\Crashlog"
                $loc_logDir = "C:\ProgramData\Avid\Support\Logs"
                $loc_fatalDir = "C:\users\Public\Documents\Avid Media Composer\Avid FatalErrorReports"

                    # Remove old logs
                remove-item $dep_crashDir\* -Force
                remove-item $dep_logDir\* -Force
                remove-item $dep_fatalDir\* -Force
                gci $dep_baseDir\* | where { ! $_.PSIsContainer } | remove-item -force
    
                    # Get date-time and avid exit code 
                $date = (get-date).ToString("yyyy.MM.dd HH.mm.ss")
                $code = $process.ExitCode
    
                    # If task manager used to exit, override the exit code
                if($process.ExitCode -eq 1){
                    $code = "1 - Task Manager"
                    }
            
                    # get the logs and copy them to their respective folders
                $crashes = gci $loc_crashDir | ? {$_.LastWriteTime -gt $startTime}
                foreach($crash in $crashes){
                    Copy-Item $crash.fullname $dep_crashDir\$crash
                    }
                $logs = gci -Recurse $loc_logDir | ? {$_.LastWriteTime -gt $startTime} | where { ! $_.PSIsContainer }
                foreach($log in $logs){
                    Copy-Item $log.fullname $dep_logDir\$log
                    }
                $fatals = gci $loc_fatalDir | ? {$_.LastWriteTime -gt $startTime}
                foreach($fatal in $fatals){
                    Copy-Item $fatal.fullname $dep_fatalDir\$fatal
                    }

                    # Create blank files with necessary information
                New-Item $dep_baseDir\$date
                New-Item $dep_baseDir\$hostname
                New-Item $dep_baseDir\$username
                New-Item $dep_baseDir\"Exit code $code"
            
                    # Get network drives and output to a txt file
                Get-PSDrive | select displayroot -ExpandProperty displayroot | Out-File $dep_baseDir\Mounted-Spaces.txt
    
                    # Set zip name and make the zip
                $zipname = $hostname + " - " + $date + ".zip"
                $ziploc = $dep_zipDir + "\" + $zipname
                Compress-Archive -Path $dep_baseDir\* -DestinationPath $ziploc -Force

                    # If upload specified, set variables and upload the zip
                if($StartMode -eq "LoggingAndUpload"){
                
                        # Set the credentials and upload location
                    $user = "domain\serviceaccount"
                    $secure = ConvertTo-SecureString "Pass" -AsPlainText -Force
                    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $secure
                    $crashRoot = "https://internal.server.domain/CrashReports"
                
                        # Upload the zips
                    Start-BitsTransfer -Authentication Ntlm -Source $ziploc -Destination $("$crashroot/$zipname") -TransferType Upload -Credential $Credential -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    }
                }
            }
        }
    }