function Install-nVidia-Drivers{
        [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('21.12','22.7','23.12','24.10')]
        [String]$AvidVersion,
        [Switch]$Automatic,
        [Switch]$Debugging
        )
    
    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}

    if($Version -like "22*"){$nviVersion = "513.91"}
    if($Version -like "23*"){$nviVersion = "537.42"}
    if($Version -eq "24.10"){$nviVersion = "552.86"}

    $localNviRoot = "C:\Deployment\Applications\Required"
    if((test-path $localNviRoot) -eq $false){
        mkdir $localNviRoot
        }
    if((Get-CimInstance -ClassName win32_videocontroller | where Name -like "*Quadro*") -ne $null){
    
        if($Version -like "22*"){
            $uri = "https://us.download.nvidia.com/Windows/Quadro_Certified/513.91/513.91-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"
            $nviName = "Quadro-513.91.exe"
            $dlDest = $localNviRoot + "\" + $nviName
            $directDownload = $true 
            }

        if($Version -like "23*"){
            $uri = "https://us.download.nvidia.com/Windows/Quadro_Certified/537.42/537.42-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"
            $nviName = "Quadro-537.42.exe"
            $dlDest = $localNviRoot + "\" + $nviName
            $directDownload = $true 
            }
    
        if($Version -eq "24.10"){
            $uri = "https://us.download.nvidia.com/Windows/Quadro_Certified/552.86/552.86-quadro-rtx-desktop-notebook-win10-win11-64bit-international-dch-whql.exe"
            $nviName = "Quadro-552.86.exe"
            $dlDest = $localNviRoot + "\" + $nviName
            $directDownload = $true 
            }
        }
    if((Get-CimInstance -ClassName win32_videocontroller | where Name -like "*GeForce*") -ne $null){
        }

    if((Test-Path $dlDest) -eq $false){
        if($directDownload){
            $downloadParams=@{
                Source = "$uri"
                Destination = $dlDest
                Description = "Downloading quadro driver version $nviVersion from nVidia site"
                }
            Start-BitsTransfer @downloadParams
            }
        }

    Write-Host -ForegroundColor Cyan "Installing nVidia driver $nviVersion"
    $nviInstall = Start-Process $dlDest -ArgumentList @('/s','/noreboot') -PassThru -Wait
    $nid = $nviInstall.Id
    $nExit = $nviInstall.ExitCode
    if($Debugging -eq $true){write-host -ForegroundColor DarkYellow "Nvidia Install Exit Code: $nExit"}
    Write-Host "Operation complete"

    }