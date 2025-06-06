### Set email settings

$smtpServer = "smtp-relay.gmail.com"
$sender = "Global Storage <email@domain.com>"
$recipients = "email@domain.com"
$week = get-date -UFormat %V
$day = get-date -format "dddd"
$subject = "Global Storage - Week $week - $day"


### Create empty array for final outputs

$allused = @()


### Get SNMP data from Nexis and Rushes systems

$nexis01usedraw = Get-SnmpData -Community SNMPCOMMUNITY -OID 1.3.6.1.4.1.526.20.4.3.0 -IP 192.168.100.11 | Select-Object Data -ExpandProperty Data
$nexis02usedraw = Get-SnmpData -Community SNMPCOMMUNITY -OID 1.3.6.1.4.1.526.20.4.3.0 -IP 192.168.100.13 | Select-Object Data -ExpandProperty Data

$rushes01usedraw = Get-SnmpData -Community SNMPCOMMUNITY -OID 1.3.6.1.2.1.25.2.3.1.6.2 -IP 10.20.15.35 | Select-Object Data -ExpandProperty Data
$rushes02usedraw = Get-SnmpData -Community SNMPCOMMUNITY -OID 1.3.6.1.2.1.25.2.3.1.6.2 -IP 10.10.15.103 | Select-Object Data -ExpandProperty Data


### Convert Nexis to TB and round to nearest 2 decimals
### Then add to the array

$nexis01used = [math]::Round(($nexis01usedraw / 1048576),2)
$allused += [pscustomobject]@{System="Nexis One";"Used TB"=$nexis01used}
$nexis02used = [math]::Round(($nexis02usedraw / 1048576),2)
$allused += [pscustomobject]@{System="Nexis Two";"Used TB"=$nexis02used}


### Convert Rushes to an integer from string
### Then convert to terabytes by multiplying by sector size and converting bytes to terabytes

$rushes01usedraw = [Convert]::ToInt32($rushes01usedraw)
$rushes02usedraw = [Convert]::ToInt32($rushes02usedraw)

$rushes01usedreal = ($rushes01usedraw * 32768)/1099511627776
$rushes02usedreal = ($rushes02usedraw * 65535)/1099511627776


### If the raw number is negative, subract the converted terabytes from the total available storage, then round it to 2 decimals
### If the raw number is positive, round it to 2 decimals
### Then add the result to the array

if($rushes01usedraw -lt 0){$rushes01used = [math]::Round(((127-($rushes01usedreal)*-1)),2)}
else{$rushes01used = [math]::Round(($rushes01usedreal),2)}
$allused += [pscustomobject]@{System="Rushes One";"Used TB"=$rushes01used}

if($rushes02usedraw -lt 0){$rushes02used = [math]::Round(((145.52-($rushes02usedreal)*-1)),2)}
else{$rushes02used = [math]::Round(($rushes02usedreal),2)}
$allused += [pscustomobject]@{System="Rushes Two";"Used TB"=$rushes02used}


### Convert finalised array to HTML for the email and create email body as html

$allusedhtml = [PSCustomobject]$allused | ConvertTo-Html -Fragment -As Table

$body = @"
<b>Global Storage Space Update:</b><br /><br />
$allusedhtml
"@


### Send the email

Send-MailMessage -SmtpServer $smtpServer -from $sender -to $recipients -subject $subject -BodyAsHtml $body


