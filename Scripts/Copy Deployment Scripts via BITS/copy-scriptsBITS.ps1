$user = "domain\serviceaccount"
$secure = ConvertTo-SecureString "pass" -AsPlainText -Force
$psddsCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $secure
$psddsAppRoots = "https://internal.server/appdeployment"
$root = "C:\Deployment"
if (!$(Test-Path($root))) {
        New-Item $root -type directory -Force}



function Get-PSDAppsScriptsWeb {
    param (
        [string] $content,
        [string] $destination
    )
    $maxAttempts = 3
    $attempts = 0
    $RetryInterval = 5
    $Retry = $True

    while ($Retry) {
        $attempts++
        try {
            $fullSource = "$psddsAppRoots" + "/" + "$content"
            $fullSource = $fullSource.Replace("\", "/")

            $request = [System.Net.WebRequest]::Create($fullSource)
            $topUri = new-object system.uri $fullSource
            $prefixLen = $topUri.LocalPath.Length

            $request.UserAgent = "PSD"
            $request.Method = "PROPFIND"
            $request.ContentType = "text/xml"
            $request.Headers.Set("Depth", "infinity")
            $request.Credentials = $psddsCredential

            $response = $request.GetResponse()
            $Retry = $False
            }
        catch {

            if ($attempts -ge $maxAttempts) {
                # Needs testing and validation
                $Message = "Unable to Retrieve directory listing of $($fullSource) via WebDAV. Error message: $($_.Exception.Message)"
                Start-Process PowerShell -Wait
                Throw
                }
            else {
                Start-Sleep -Seconds $RetryInterval
                }
            }
        }

    if ($response -ne $null) {
        Move-Item C:\Deployment\Scripts C:\Deployment\Scripts.old -Force
        
        $sr = new-object System.IO.StreamReader -ArgumentList $response.GetResponseStream(), [System.Encoding]::Default
        [xml]$xml = $sr.ReadToEnd()

        # Get the list of files and folders, to make this easier to work with
        $results = @()
        $xml.multistatus.response | ? { $_.href -ine $url } | % {
            $uri = new-object system.uri $_.href
            $dest = $uri.LocalPath.Replace("/", "\").Substring($prefixLen).Trim("\")
            $obj = [PSCustomObject]@{
                href         = $_.href
                name         = $_.propstat.prop.displayname
                iscollection = $_.propstat.prop.iscollection
                destination  = $dest
                }
            $results += $obj
            }

        # Create the folder structure
        $results | ? { $_.iscollection -eq "1" } | sort destination | % {
            $folder = "$destination\$($_.destination)"
            if (Test-Path $folder) {
                # Already exists
            }
            else {
                $null = MkDir $folder
                }
            }
        
        # Create the list of files to download
        $sourceUrl = @()
        $destFile = @()
        $results | ? { $_.iscollection -eq "0" } | sort destination | % {
            $sourceUrl += [string]$_.href
            $fullFile = "$destination\$($_.destination)"
            $destFile += [string]$fullFile
            }
        # Do the download using BITS
        $bitsJob = Start-BitsTransfer -Authentication Ntlm -Credential $psddsCredential -Source $sourceUrl -Destination $destFile -TransferType Download -DisplayName "Scripts Transfer" -Priority High -ErrorVariable bitserror
        
        if($bitserror){
            
            # If BITS had an error, move the old scripts folder back
            Remove-Item C:\Deployment\Scripts -Recurse -Force
            Move-Item C:\Deployment\Scripts.old C:\Deployment\Scripts -Force
            }
        else{
            
            # Set scripts folder attributes
            Set-ItemProperty -Path "C:\Deployment" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::Hidden)
            Set-ItemProperty -Path "C:\Deployment\Scripts" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::Hidden)
            $scripts = gci -Recurse C:\Deployment\Scripts -Force
            foreach($item in $scripts){
                $item.Attributes = 'Hidden, System'
                }

            # Unhide Avid shortcuts
            Set-ItemProperty -Path "C:\Deployment\Scripts\MediaComposer\Avid Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
            Set-ItemProperty -Path "C:\Deployment\Scripts\MediaComposer\Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
	        gci "C:\Deployment\Scripts\MediaComposer\Logs" -Recurse -Force | Set-ItemProperty -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
            Set-ItemProperty -Path "C:\Deployment\Scripts\MediaComposer\Logs" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
            Set-ItemProperty -Path "C:\Deployment\Scripts\MediaComposer\Zips" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
            Remove-Item C:\Deployment\Scripts.old -Recurse -Force
            }
        }
    }

Get-PSDAppsScriptsWeb -content Scripts -destination "C:\Deployment\Scripts"


# Set previously copied Avid shortcuts back to unhidden as a precaution.
Set-ItemProperty -Path "C:\Users\Public\Desktop\Avid Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
Set-ItemProperty -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Avid\Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
Set-ItemProperty -Path "C:\Users\Public\Desktop\Avid Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)
Set-ItemProperty -Path "C:\Users\Public\Desktop\Avid Media Composer.lnk" -Name Attributes -Value ($attributes -bor [System.IO.FileAttributes]::UnHidden)