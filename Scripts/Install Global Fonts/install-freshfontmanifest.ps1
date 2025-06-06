Add-Type -AssemblyName PresentationFramework -PassThru | Out-Null

if([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") -ne $true){
    Write-Host "`nPlease run as administrator`n" -ForegroundColor White -BackgroundColor Red
    exit
    }

$manifest = import-csv \\server\share\FontStore\!_Extra\font_manifest.csv
$installedfonts = $null
$installedarray= @()

foreach($font in $manifest){
    $fontfile = $font.font
    if((@($installedfonts) -like $fontfile).Count -gt 0){
        $installedarray += "$fontfile"
        }
    else{
        write-host "Installing $fontfile"
        $gt = [Windows.Media.GlyphTypeface]::new($font.path)
        $family = $gt.Win32FamilyNames['en-us']
        if ($null -eq $family) { $family = $gt.Win32FamilyNames.Values.Item(0) }
        $face = $gt.Win32FaceNames['en-us']
        if ($null -eq $face) { $face = $gt.Win32FaceNames.Values.Item(0) }
        $fontName = ("$family $face").Trim()
        if($fontFile -like "*.ttf") {  
			$fontNameNew = "$fontName (TrueType)"
            } 
        if($fontFile -like "*.otf") {
            $fontNameNew = "$fontName (OpenType)"
            }
        Copy-Item -Path $font.path -Destination ("$($env:windir)\Fonts\" + $fontfile) -Force
        New-ItemProperty -Name $fontNameNew -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $fontFile -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }

$include = @("*.ttf", "*.otf", "*.ttc")
$exclude = @("*_0.ttf", "*_0.otf", "*_0.ttc")
$installedfonts = gci C:\Windows\Fonts -Recurse -Include $include -Exclude $exclude

foreach($font in $installedfonts){
    $fontfile = $font.name
    $fontloc = $font.FullName
    if((@($manifest.font) -like $fontfile).Count -lt 1){write-host "Copying $fontfile"
        copy $fontloc \\server\share\FontStore\temp\$fontfile
        }    
    }

$users = gci C:\Users
foreach($user in $users){
    $name = $user.name
    $installedfonts = gci C:\users\$name\appdata\local\microsoft\windows\fonts -Recurse -Include $include -Exclude $exclude
        foreach($font in $installedfonts){
        $fontfile = $font.name
        $fontloc = $font.FullName
        if((@($manifest.font) -like $fontfile).Count -lt 1){write-host "Copying $fontfile"
            copy $fontloc \\server\share\FontStore\temp\$fontfile
            }    
        }
    }
