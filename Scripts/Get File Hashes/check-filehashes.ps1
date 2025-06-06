Function check-filehashes{

Param(
    [switch] $compare,
    [parameter(Mandatory)][string] $SourceFolder,
    [string] $DestinationFolder
    )

if($compare -eq $true -and $DestinationFolder -eq $null){Write-Host "Please specify destination folder using -destinationfolder"}

$i = 0
$sourcefiles = gci -Recurse $SourceFolder | where {! $_.PSIsContainer -and $_.FullName -inotlike "*screensaver*"}
$sourcehashes = @()
$sourcecount = $sourcefiles.count
foreach ($file in $sourcefiles){
    $i++
    write-host "`rCalculating hash for source file $i/$sourcecount" -NoNewline
    $shortname = $file.name
    $name = $file.fullName
    $path = $name.Substring(3)
    $hash = (get-filehash $name -Algorithm MD5).Hash
    $sourcehashes += [pscustomobject]@{"File Location"=$shortname;"MD5 Hash"=$hash;"Path"=$path}
    }

if($compare -eq $true){

$i = 0
$destfiles = gci -Recurse $DestinationFolder | where {! $_.PSIsContainer}
$desthashes = @()
$destcount = $destfiles.count
foreach ($file in $destfiles){
    $i++
    write-host "`rCalculating hash for destination file $i/$destcount" -NoNewline
    $shortname = $file.name
    $name = $file.fullName
    $path = $name.Substring(3)
    $hash = (get-filehash $name -Algorithm MD5).Hash
    $desthashes += [pscustomobject]@{"File Location"=$shortname;"MD5 Hash"=$hash;"Path"=$path}
    }
$sourcehashes.count
$desthashes.count
}

$sourcehashes | Export-Csv C:\location\sourcehash.csv
$desthashes | Export-Csv C:\location\desthash.csv

}