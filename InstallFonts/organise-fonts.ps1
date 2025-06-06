Add-Type -AssemblyName PresentationFramework
$include = @("*.ttf", "*.otf", "*.ttc")
$exclude = @("*_0.ttf", "*_0.otf", "*_0.ttc")
$fonts = gci "D:\Deployment\FontStore\temp" -Recurse -include $include -Exclude $exclude

foreach($font in $fonts){
    $fontfile = $font.name
    $path = $font.FullName
    $gt = [Windows.Media.GlyphTypeface]::new($font.fullname)
    $family = $gt.Win32FamilyNames['en-us']
    if ($null -eq $family) { $family = $gt.Win32FamilyNames.Values.Item(0) }
    $face = $gt.Win32FaceNames['en-us']
    if ($null -eq $face) { $face = $gt.Win32FaceNames.Values.Item(0) }
    $root = ($family.Split())[0]
    if((test-path D:\Deployment\FontStore\!_Extra\$root)-eq $false){mkdir D:\Deployment\FontStore\!_Extra\$root}
    if((test-path D:\Deployment\FontStore\!_Extra\$root\$family)-eq $false){mkdir D:\Deployment\FontStore\!_Extra\$root\$family}
    Copy-Item $path D:\Deployment\FontStore\!_Extra\$root\$family\$fontfile -Force
    remove-Item $path -force
    }

$fonts = gci D:\Deployment\FontStore\!_Extra -Recurse -include $include | where { ! $_.PSIsContainer }

$manifest = @()

foreach($font in $fonts){
    $family = ($font.DirectoryName).Split('\')[-1]
    $fontname = $font.name
    $directory = $font.fullname
    $directory = $directory.replace("D:\Deployment","\\server\share")
    $manifest += [pscustomobject]@{Family=$family;Font=$fontname;Path=$directory}
    }

Remove-Item D:\Deployment\FontStore\!_Extra\font_manifest.csv -Force
$manifest | Export-Csv D:\Deployment\FontStore\!_Extra\font_manifest.csv