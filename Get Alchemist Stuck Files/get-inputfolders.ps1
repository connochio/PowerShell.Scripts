#### GLOBAL VARIABLES ##########

$path = "\\server\path\"
$recipients = "email@domain.com"

<### DESCRIPTION OF ACTIONS ####

(26-27)   Create a new array for storing file names, then run the initial search for folders called 'Input' in the path set in global variables

(29-30)   For each folder found, run a search for all files excluding those associated with a current upload or download

(32-35)   For every file found, check creation date and compare that to today's date
          If the creation date is older that now by 6 or more hours, shorten the name by removing the original search path
          Now add the resulting short name to the array created at the start

(40)      Count the number of files contained in the array

(42-49)   Create a HTML body for the email containing the array count and array contents

(51-52)   If 1 or more files are found, send the message to the recipients set in the global variables with the created body 

#>

#### SCRIPT START ##############

$stuckFiles = New-Object System.Collections.ArrayList
$inputFolders = Get-ChildItem -Path $path -Recurse -Filter "Input" | ?{ $_.PSIsContainer }

foreach ($folder in $inputFolders) {
    $files = Get-ChildItem -recurse -path $folder.FullName -Exclude "#work_file#*"

    foreach ($file in $files) {
        if ($file.CreationTime -lt (Get-Date).AddHours(-6)){
            $shortName = $File.FullName.Replace("\\server\path","")
            $stuckFiles.add("$shortName <br />") | Out-Null
        }
    }
}

$stuckFilesCount = $stuckFiles.count

$body = @"
<b>$stuckFileCount files were found to be older than 6 hours. <br />
Please verify that they have been successfully converted or re-submitted. <br />
<br />
$path</b> <br />
<br />
$stuckFiles
"@

if ($stuckFilesCount -ne 0){
    Send-MailMessage -to $recipients -from "Alchemist Report <email@domain.com>" -Subject "Alchemist Conversions - $stuckFilesCount old files found" -BodyAsHtml $body -SmtpServer "smtp-relay.gmail.com"
}