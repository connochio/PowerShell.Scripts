Function Pre-Stage-Machine {
    
    [cmdletbinding()]
    Param (
        [ValidateSet("All-0800","All-0805","All-0810","Week-0800","Week-0805","Week-0810")]
        [String]$AutoPower
        )
    cd $PSScriptRoot

    $7zip = "7zip\7z2409-x64.msi"
    $Action1 = "Action1\action1_agent(run_Post).msi"
    $HPBCU = "HPBIOS\HPBIOSConfigurationUtility.msi"
    #Start-Process msiexec -ArgumentList "/i `"$pkg`"","/qn";


    ### Uninstall Sophos ###

    start-process "C:\Program Files\Sophos\Sophos Endpoint Agent\SophosUninstall.exe" -ArgumentList "--quiet" -PassThru -Wait

    ### Install HP BIOS Configuration Utility ###

    Start-Process msiexec -ArgumentList "/i `"$HPBCU`"","/qn","/norestart"

    ### Install Action1 ###

    if((Get-Package Action1*) -eq $null){
        Start-Process msiexec -ArgumentList "/i `"$Action1`"","/qn","/norestart"
        }

    ### Install 7Zip ###

    if((Get-Package 7-zip*) -eq $null){
        Start-Process msiexec -ArgumentList "/i `"$7zip`"","/qn","/norestart"
        }

    ### Set Auto Power On State ###
    ## Only if $AutoPower is set ##

    if($AutoPower){
        if($AutoPower -like "All-*"){
            $saturday = "Enable"
            $sunday = "Enable"
            }
        if($AutoPower -like "Week-*"){
            $saturday = "Disable"
            $sunday = "Disable"
            }
        if($AutoPower -like "*-800"){
            $minute = "0"
            }
        if($AutoPower -like "*-805"){
            $minute = "05"
            }
        if($AutoPower -like "*-810"){
            $minute = "10"        
            }
            
        if(( Get-CimInstance -ClassName win32_computersystem | where {($_.Manufacturer -like "HP*") -or ($_.Manufacturer -like "Hewlett*")}) -ne $null){
        $Interface = Get-WmiObject -Namespace root\HP\InstrumentedBIOS -Class HP_BIOSSettingInterface

        $interface.SetBIOSSetting("Monday","Enable")
        $interface.SetBIOSSetting("Tuesday","Enable")
        $interface.SetBIOSSetting("Wednesday","Enable")
        $interface.SetBIOSSetting("Thursday","Enable")
        $interface.SetBIOSSetting("Friday","Enable")
        $interface.SetBIOSSetting("Saturday","$saturday")
        $interface.SetBIOSSetting("Sunday","$sunday")
        $interface.SetBIOSSetting("BIOS Power-On Hour","8")
        $interface.SetBIOSSetting("BIOS Power-On Minute","$minute")
        $interface.SetBIOSSetting("BIOS Power-On Time (hh:mm)","08:$minute")
        }
    }
    
}