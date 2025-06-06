$allRushesDrives = @()
$allDDrives = @()
$totalUsed = @()

$rushesfolders = gci D:\Rushes | Where-Object {$_.PSIsContainer -eq $true}
foreach ($folder in $rushesfolders){
    $name = $folder.fullname
    $share = $folder.Name
    $files = gci $folder.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
    $sizeGBraw =  [math]::Round(($files.sum / 1GB),2)
    $sizeTBraw =  [math]::Round(($files.sum / 1TB),2)
    $sizeGB = "$sizeGBraw GB"
    $sizeTB = "$sizeTBraw TB"
    $allRushesDrives += [pscustomobject]@{Share=$share;" "="         ";"Used TB"=$sizeTB;"  "="         ";"Used GB"=$sizeGB}
    }

$dfolders = gci D:\ | Where-Object {$_.PSIsContainer -eq $true}
foreach ($folder in $dfolders){
    $name = $folder.fullname
    $share = $folder.Name
    $files = gci $folder.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
    $sizeGBraw =  [math]::Round(($files.sum / 1GB),2)
    $sizeTBraw =  [math]::Round(($files.sum / 1TB),2)
    $totalused += $sizeTBraw
    $sizeGB = "$sizeGBraw GB"
    $sizeTB = "$sizeTBraw TB"
    $allDDrives += [pscustomobject]@{Share=$share;" "="         ";"Used TB"=$sizeTB;"  "="         ";"Used GB"=$sizeGB}
    }

$rushestable = [PSCustomobject]$allRushesdrives| ConvertTo-Html -Fragment -As Table
$dtable = [PSCustomobject]$allDdrives| ConvertTo-Html -Fragment -As Table
$dtotalused = $totalUsed | Measure-Object -Sum
$overall = $dtotalused.sum

$bodyit = @"
<b>Rushes One Total Used Space: $overall TB<br />
<br />Project Usage:</b><br /><br />
$rushestable
<br /><b>Share Usage:</b><br /><br />
$dtable
"@

$bodybookings = @"
<b>Project Usage:</b><br /><br />
$rushestable
"@

$week = get-date -UFormat %V

$smtpServer = "smtp-relay.gmail.com"
$sender = "Rushes 01 Storage <email@domain.com>"
$recipientit = "email@domain.com"
$recipientbookings = "email@domain.com"

$subject = "Week $week - Rushes 01 Storage Report"
Send-MailMessage -SmtpServer $smtpServer -To $recipientit -From $sender -BodyAsHtml $bodyit -Subject $subject
Send-MailMessage -SmtpServer $smtpServer -To $recipientbookings -From $sender -BodyAsHtml $bodybookings -Subject $subject
