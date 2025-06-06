function Install-Avid{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('21.12','22.7','23.12','24.10')]
        [String]$Version,
        [Switch]$Automatic,
        [Switch]$Upgrade,
        [Switch]$Debugging,
        [Switch]$SuperDebugging,
        [Switch]$FromExtract
        )
    
    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}
    
    if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){
        Write-Warning "This module must be run in an Administrative context"
        Write-Warning "Please relaunch PowerShell as Administrator and rerun Install-Avid"
        break outer
        }

    if($Version -eq "22.7"){$instVersion = "22.7.0"}
    if($Version -eq "23.12"){$instVersion = "23.12.4"}
    if($Version -eq "24.10"){$instVersion = "24.10.0"}

    if($automatic -eq $true){
        Download-Avid -Version $Version -Automatic -FromExtract
        Extract-Avid -Version $Version -Automatic

        }


    $programs = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
    $previousInstall = Get-ChildItem -Path $programs | Get-ItemProperty | Where-Object {$_.DisplayName -like "Avid Media Composer*"}
    
    if($previousInstall -ne $null){
        $uninstallString = ($previousInstall.UninstallString).split(" ")[1]
        [string]$prevMajor = $previousInstall.VersionMajor
        [string]$prevMinor = $previousInstall.VersionMinor
        $previousVersion = $prevMajor + "." + $prevMinor
        
        if($Automatic -ne $true){
            do{
                $uninstallConfirm = Read-Host "Would you like to uninstall the previous version ($previousVersion)? (y/n)"
                $uninstallConfirm.ToLower() | Out-Null
                }
            until(($uninstallConfirm -eq "n" ) -or ($uninstallConfirm -eq "y"))
            }
        else{$uninstallConfirm = "y"}
        
        if($uninstallConfirm -eq "y"){
            Write-Host -ForegroundColor Cyan "INFO: Uninstalling Avid $previousVersion"

            $uninstall = Start-Process msiexec.exe -ArgumentList @($uninstallString,'/qn','/norestart') -PassThru
            $uid = $uninstall.Id
            do{
                start-sleep -Milliseconds 100
                }
            until((Get-Process -id $uid) -eq $null)
            $uExit = $uninstall.ExitCode
            if($Debugging -eq $true){Write-Host -ForegroundColor DarkYellow "    DEBUG: Avid Uninstall Exit Code: $uExit"}
            if(($uExit -eq 0) -or ($uExit -eq 3010)){
                Write-host -ForegroundColor Cyan "INFO: Media Composer has been uninstalled"
                }
            }
        else{
            Write-Warning "Media Composer $version cannot be installed"
            Write-Warning "Please uninstall Media Composer $previousVersion manually or run Install-Avid again"
            break outer
            }
        }

    Write-Host -ForegroundColor Cyan "INFO: Installing Avid $Version"
    $install = Start-Process "C:\Deployment\Applications\NLE\MediaComposer$instVersion\MediaComposer\Installers\MediaComposer\Setup.exe" -ArgumentList @("/s","/v""OPEN_NDI_SELECT=1 OPEN_SRT_SELECT=1""","/v""/qn /norestart""") -PassThru
    $iid = $install.Id
    do{
        start-sleep -Milliseconds 100
        }
    until((Get-Process -id $iid) -eq $null)
    $iExit = $install.ExitCode
    if($Debugging -eq $true){Write-Host -ForegroundColor DarkYellow "    DEBUG: Avid Install Exit Code: $iExit"}
    
    if(($iexit = 3010) -or ($iexit = 0)){
        Write-host -ForegroundColor Green "INFO: Media Composer version $Version has been installed"
        if($Automatic -eq $true){
            Install-nVidia-Drivers -AvidVersion $Version -Automatic
            }
        Uninstall-Bonjour
        Write-Host -ForegroundColor Green "INFO: Please restart the machine to complete installation"

        }
    else{
        Write-Warning "Media Composer version $Version may not have installed successfully"
        Write-Warning "Please verify and/or install manually from C:\Deployment\Applications\NLE\MediaComposer$instVersion"
        break outer
        }
            
    }