function Set-AvidSiteSettings{
    [cmdletbinding()]
    Param (
        [Switch]$Force,
        [Switch]$Debugging,
        [Switch]$SuperDebugging
    )

    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}

    if($force){
        }
    else{
        }
    }