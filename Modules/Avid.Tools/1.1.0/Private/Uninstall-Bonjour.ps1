$uninstallString = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\windows\CurrentVersion\Uninstall\*' | ?{$_.DisplayName -like "Bonjour"}).UninstallString
if ($uninstallString -ne $null)
{
    & cmd /c $uninstallString /quiet /norestart
}