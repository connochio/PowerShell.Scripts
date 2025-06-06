function Download-Avid{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('21.12','22.7','23.12','24.10')]
        [String]$Version,
        [Switch]$Automatic,
        [Switch]$Debugging,
        [Switch]$SuperDebugging,
        [Switch]$FromExtract
        )
    
    if($SuperDebugging -eq $false){$ErrorActionPreference = “silentlycontinue”}
    else{$Debugging = $true}
    
    # Set proper version syntax
    if($Version -eq "22.7"){$dowVersion = "22.7.0"}
    if($Version -eq "23.12"){$dowVersion = "23.12.4"}
    if($Version -eq "24.10"){$dowVersion = "24.10.0"}
    $archive = "C:\Deployment\Applications\NLE\Media_Composer_" + $dowVersion + "_Win.zip"

    $localMcRoot = "C:\Deployment\Applications\NLE"
    if((test-path $localMcRoot) -eq $false){
        mkdir $localMcRoot
        }
    
    if($version -eq "21.12"){
        Write-Warning "This version is not available from the Avid CDN"
        Write-Warning "The download cannot be processed"}
    
    if($Version -eq "22.7"){
        Write-Warning "This version is not available from the Avid CDN"
        Write-Warning "The download cannot be processed"}
    
    if($Version -eq "23.12"){
        $uri = "https://cdn.avid.com/Media_Composer/2023.12.4/FDOF1OK5/Media_Composer_23.12.4_Win.zip"
        $mcName = $uri.Split("/")[-1]
        $dlDest = $localMcRoot + "\" + $mcName
        $directDownload = $true 
        }
    
    if($Version -eq "24.10"){
        $uri = "https://cdn.avid.com/Media_Composer/2024.10/F5IYM5Q6/Media_Composer_24.10.0_Win.zip"
        $mcName = $uri.Split("/")[-1]
        $dlDest = $localMcRoot + "\" + $mcName
        $directDownload = $true 
        }
    
    if((Test-Path $archive) -eq $false){
        if($directDownload){
            $downloadParams=@{
                Source = "$uri"
                Destination = "$dlDest"
                Description = "Downloading Media Composer version $Version from Avid CDN"
                }
            Start-BitsTransfer @downloadParams
            }
        }

    if($FromExtract -ne $true){
        do{
            $extractConfirm = Read-Host "Would you like to extract the Avid Archive? (y/n)"
            $extractConfirm.ToLower() | Out-Null
            }
        until(($extractConfirm -eq "n" ) -or ($extractConfirm -eq "y"))
        if($extractConfirm -eq "y"){
            Extract-Avid -Version $version -FromDownload
            }
        }
    }