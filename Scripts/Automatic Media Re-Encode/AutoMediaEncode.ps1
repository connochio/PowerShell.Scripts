#region Global Variables

$sourcefolder = "C:\source\folder"
$destinationfolder = "C:\destination\folder"
$newfileext = "mkv" 
$sonarrURL = "http://localhost:8989/api/v3/command"
$sonarrAPI = "sonarrAPIkey"
$filter = @("*sample*", "*.txt", "*.nfo", "*.EXE")
$excluded = @("*.mp4", "*.mkv", "*.avi", "*.mpeg4", "*.ts", "*.!ut")
$included = @("*.mp4", "*.mkv", "*.avi", "*.mpeg4", "*.ts")
$progressroot = $sourcefolder + "\" + "In Progress"
$code=@' 
[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
  public static extern void SetThreadExecutionState(uint esFlags);
'@
$ste = Add-Type -memberDefinition $code -name System -namespace Win32 -passThru 
$ES_SYSTEM_REQUIRED = [uint32]"0x00000001"
$ES_CONTINUOUS = [uint32]"0x80000000"
$run = 0


#endregion

#region Functions

function Move-HEVC{
    $265Alias = @("*x.265*","*x265*","*h.265*","*h265*","*HEVC*")
    $files = gci $sourcefolder
    foreach($file in $files){
        foreach ($pattern in $265Alias){
            if($file.name -like "$pattern"){
                write-host "it's hevc!"
                move-item -LiteralPath $file.fullname -Destination $destinationfolder
                break
                }
            }
        }
    }

function Clear-Unwanted{
    gci $sourcefolder\* -Recurse -Include $filter | where { ! $_.PSIsContainer } | foreach {Remove-Item -LiteralPath $_.FullName -Force}
    gci $sourcefolder\* -Recurse -Exclude $excluded | where { ! $_.PSIsContainer } | foreach ($_) {Remove-Item -LiteralPath $_.FullName -Force}
    }

function Get-Queued{
    $queuedfilelist = gci $script:sourcefolder\* -Recurse -Include $included | where { ! $_.PSIsContainer } | Where {$_.FullName -notlike "*\In Progress\*" -and $_.FullName -notlike "*\Delayed\*"}
    $queuedfilelist
    }

function Clear-Folders{
    do { $empty = gci $script:sourcefolder -Recurse | Where-Object -FilterScript {$_.PSIsContainer -eq $True} | Where-Object -FilterScript {($_.GetFiles().Count -eq 0) -and $_.GetDirectories().Count -eq 0}
    $empty | remove-item }
    until ($empty.count -eq 0)
    }

function Create-Progress{
    
    if ((Test-Path $script:progressroot) -eq $false) {New-Item $script:progressroot -type directory}
    ForEach ($file in $script:queuedfilelist){
        start-sleep -s 1
        $f = 0
        do {$f++;
            $progressfolder = $script:progressroot + "\" + $f
            (Test-Path $progressfolder)
            }
        until ((Test-Path $progressfolder) -eq $false)
        New-Item $progressfolder -type Directory

        Move-Item -literalpath $file -Destination $progressfolder
        }
    }

Function Set-Envs{
    param(
        [switch] $RunOn,
        [switch] $RunOff,
        [switch] $EncOn,
        [switch] $Encoff
        )

    if($RunOn){
        [Environment]::SetEnvironmentVariable("HBSRunning", $true, "User")
        [Environment]::SetEnvironmentVariable("HBSRunning", $true, "Machine")
        }
    if($RunOff){
        [Environment]::SetEnvironmentVariable("HBSRunning", $false, "User")
        [Environment]::SetEnvironmentVariable("HBSRunning", $false, "Machine")
        }
    if($EnvOn){
        [Environment]::SetEnvironmentVariable("HBSEncoding", $true, "User")
        [Environment]::SetEnvironmentVariable("HBSEncoding", $true, "Machine")
        }
    if($EnvOff){
        [Environment]::SetEnvironmentVariable("HBSEncoding", $false, "User")
        [Environment]::SetEnvironmentVariable("HBSEncoding", $false, "Machine")
        }

}

Function Re-encode{
    if($script:run -gt 9){break}
    $script:run++

    Move-HEVC

    $filelist = gci -LiteralPath $script:progressroot -Filter *.* -Recurse | where { ! $_.PSIsContainer }
    $filecount = $filelist.count

    if($filecount -eq 0){return}

    ForEach ($file in $filelist)
    {

        do { $randomtime = Get-Random -Minimum 10 -Maximum 300
        Start-Sleep -m $randomtime } 
        until ($env:HBSEncoding -eq $false)
    
        Set-Envs -EncOn

        $encodesetting = "Default-All-RF20"
        If($file.Name -like '`[*`]*'){
            $encodesetting = "Default-All-RF18"}
        
        $oldfile = $file.DirectoryName + "\" + $file.BaseName + $file.Extension;
        $newfile = $destinationfolder + "\" + $file.BaseName + ".$newfileext";
        $oldfilebase = $file.BaseName + $file.Extension;
    
        if(((get-process -Name "handbrakecli*").count) -lt 1){
            $proc = Start-Process "C:\Program Files\HandBrake\HandBrakeCLI.exe" -WindowStyle Minimized -ArgumentList "--preset-import-gui --preset `"$encodesetting`" -i `"$oldfile`" -o `"$newfile`"" -PassThru 
            }
        else{exit}

        Start-Sleep -Seconds 1
    
        $proc.ProcessorAffinity=43695
        $proc.PriorityClass="BelowNormal"
    
        do {
            Start-Sleep -s 1
            } 
            until ($proc.HasExited -eq $true)
    
        if ($proc.exitcode -eq 0){    
            Remove-Item -LiteralPath "$oldfile" -force    
        
            $params = @{"name"="downloadedepisodesscan";"path"="$newfile";} | ConvertTo-Json
            irm -Uri $script:sonarrURL -Method Post -Body $params -Headers @{"X-Api-Key"="$script:sonarrAPI"}
            }

        else { 
            $returnfile = $sourcefolder + "\" + $file.BaseName + $file.Extension;
            Move-Item -LiteralPath $oldfile -Destination $returnfile -Force
            Remove-Item -LiteralPath $newfile -Force
            }
    
      
        Set-Envs -Encoff
    
        Clear-Unwanted
        $script:queuedfilelist = Get-Queued
        if($script:queuedfilelist.count -ne 0){
        Create-Progress
        Clear-Folders
            }
        }

    $filelist = gci -LiteralPath $script:progressroot -Filter *.* -Recurse | where { ! $_.PSIsContainer }
    if ($filelist.count -ne 0){
    Re-encode}
    else{
        Set-Envs -RunOff
        return}

    }

#endregion

#region Do Things

if(((get-process -Name "handbrakecli*").count) -gt 0){exit}

if ($env:HBSRunning -eq $false) {
    Set-Envs -RunOn
    } 
else {exit}

Clear-Unwanted
$queuedfilelist = Get-Queued

if ($queuedfilelist.count -eq "0") {
    Set-Envs -RunOff
    Exit }

$ste::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED)

Move-HEVC
Create-Progress
Clear-Folders
Re-encode

$filelist = gci $destinationfolder -Filter *.* -Recurse | where { ! $_.PSIsContainer }
ForEach ($file in $filelist){
    $filepath = $file.fullname
    $params = @{"name"="downloadedepisodesscan";"path"="$filepath";"importMode"="Move"} | ConvertTo-Json
    irm -Uri $sonarrURL -Method Post -Body $params -Headers @{"X-Api-Key"="$sonarrAPI"; "Content-Type"="application/json"; "charset"="utf-8"}
    }
    
Clear-Folders
Clear-RecycleBin -Confirm:$False

$ste::SetThreadExecutionState($ES_CONTINUOUS)

#endregion