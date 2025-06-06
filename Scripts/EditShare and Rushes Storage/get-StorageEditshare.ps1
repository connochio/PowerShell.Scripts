$shares = (net view \\192.168.100.9 | Where-Object { $_ -match '\sDisk\s' }) -replace '\s\s+', ',' | ForEach-Object{ ($_ -split ',')[0] }
$allDrives = @()

foreach($share in $shares){
    $location = "\\192.168.100.9\" + $share
    write-host $location

    net use x: $location
    start-sleep 1
    $drive = Get-PSDrive 'X'
    $usedSize = $drive.used
    $usedSizeTB = [math]::Round(($usedSize / 1TB),2)
    $usedSizeGB = [math]::Round(($usedSize / 1GB),2)
    $freeSize = $drive.free
    $freeSizeTB = [math]::Round(($freeSize / 1TB),2)
    $freeSizeGB = [math]::Round(($freeSize / 1GB),2)
    $totalSize = $usedSize + $freeSize
    $totalSizeTB = [math]::Round(($totalSize / 1TB),2)
    $totalSizeGB = [math]::Round(($totalSize / 1GB),2)

    $sizeTB = "$usedsizeTB TB / $totalsizeTB TB"
    $sizeGB = "$usedsizeGB GB / $totalsizeGB GB"

    $allDrives += [pscustomobject]@{Share=$share;" "="         ";"Used/Assigned TB"=$sizeTB;"  "="         ";"Used/Assigned GB"=$sizeGB}
    net use x: /delete
    start-sleep 1

    }

$table = [PSCustomobject]$alldrives| ConvertTo-Html -Fragment -As Table

$body = @"
$table
"@

$week = get-date -UFormat %V

$smtpServer = "smtp-relay.gmail.com"
$sender = "EditShare Storage <email@domain.com>"
$recipient = "email@domain.com"

$subject = "Week $week - EditShare Storage Report"
Send-MailMessage -SmtpServer $smtpServer -To $recipient -From $sender -BodyAsHtml $body -Subject $subject