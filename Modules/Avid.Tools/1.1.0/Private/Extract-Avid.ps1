function Extract-Avid{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('21.12','22.7','23.12','24.10')]
        [String]$Version,
        [Switch]$Automatic,
        [Switch]$Debugging,
        [Switch]$SuperDebugging,
        [Switch]$FromDownload
        )

    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}

    # Check whether 7-zip is installed
    if((Get-Package 7-zip*) -ne $null){
        $extract = $true
        }
    else{
        Write-Warning "7-Zip not installed"
        if($Automatic -ne $true){
            do{
                $7zipInstall = Read-Host "Would you like to download and install 7-zip? (y/n)"
                $7zipInstall.ToLower() | Out-Null
                }
            until(($7zipInstall -eq "n" ) -or ($7zipInstall -eq "y"))
            }
        else{$7zipInstall = "y"}
        if($7zipInstall -eq "y"){
            if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){
                Write-Warning "Installation of 7-Zip must be run in an Administrative context"
                Write-Warning "Please relaunch PowerShell as Administrator"
                break outer
                }
            else{
                $localAppRoot = "C:\Deployment\Applications\Required"
                if((test-path $localAppRoot) -eq $false){
                    mkdir $localAppRoot
                    }
                Start-BitsTransfer -Source 'https://www.7-zip.org/a/7z2409-x64.exe' -Destination 'C:\Deployment\Applications\Required\7z2409-x64.exe' -Description "Downloading 7-Zip"
                $install = Start-Process 'C:\Deployment\Applications\Required\7z2409-x64.exe' -ArgumentList @('/S') -PassThru
                $iid = $install.Id

                do{start-sleep -Milliseconds 100}
                until((Get-Process -id $iid) -eq $null)
                $7Exit = $install.ExitCode
                if($Debugging -eq $true){Write-Host -ForegroundColor DarkYellow "    DEBUG: 7-Zip Install Exit Code: $7Exit"}
                if($7Exit -eq 0){
                    Write-Host -ForegroundColor Cyan "INFO: 7-Zip has been installed"
                    $extract = $true
                    }
                else{
                    Write-Warning "7-Zip Install failed"
                    Write-Warning "Please install manually and re-run Extract-Avid"
                    break outer
                    }
                }
            }
        if($7zipInstall -eq "n"){
            Write-Warning "Unable to continue without 7-Zip"
            Write-Warning "Please install manually or re-run Extract-Avid and and select y on the install prompt"
            }
        }
    
    # Set proper version syntax
    if($Version -eq "22.7"){$extVersion = "22.7.0"}
    if($Version -eq "23.12"){$extVersion = "23.12.4"}
    if($Version -eq "24.10"){$extVersion = "24.10.0"}

    $archive = "C:\Deployment\Applications\NLE\Media_Composer_" + $extVersion + "_Win.zip"
    $extLocArg = "-o" + '"' + "C:\Deployment\Applications\NLE\MediaComposer" + $extVersion + '"'

    if((test-path $archive) -eq $false){
        Write-Warning "Media Composer archive not found in the expected path"
        Write-Host -ForegroundColor Cyan "INFO: Expected path: C:\Deployment\Applications\NLE"
        
        if($Automatic -ne $true){
            do{
                $downloadConfirm = Read-Host "Would you like to download Media Composer directly from Avid? (y/n)"
                $downloadConfirm.ToLower() | Out-Null
                }
            until(($downloadConfirm -eq "n" ) -or ($downloadConfirm -eq "y"))
            }
        else{$downloadConfirm = "y"}

        if($downloadConfirm -eq "y"){Download-Avid -Version $version -FromExtract}
        else{
            Write-Warning "Unable to download Avid"
            Write-Warning "Please download and move Media Composer zip manually and re-run Extract-Avid"
            Write-Host -ForegroundColor Cyan "INFO: Location required for zip file is: C:\Deployment\Applications\NLE"
            break outer
            }
        }
    
    if((test-path $archive) -eq $false){
        Write-Warning "Media Composer zip still not available"
        Write-Warning "Please move Media Composer zip manually and re-run Extract-Avid"
        Write-Host -ForegroundColor Cyan "INFO: Location required for zip file is: C:\Deployment\Applications\NLE"
        break outer
        }

    if($extract){
        Write-Host -ForegroundColor Cyan "INFO: Archive extraction in progress"
        $extraction = Start-Process 'C:\Program Files\7-Zip\7z.exe' -ArgumentList @('x',$archive,$extLocArg,'-y') -PassThru -WindowStyle Minimized
        $eid = $extraction.Id
        do{
            start-sleep -Milliseconds 100
            }
        until((get-process -id $eid) -eq $null)

        if($extraction.ExitCode -eq 0){
            Write-Host -ForegroundColor Cyan "INFO: Extraction Complete"
            }
        else{
            Write-Warning "Extraction Failed"
            break outer
            }
        }
    }