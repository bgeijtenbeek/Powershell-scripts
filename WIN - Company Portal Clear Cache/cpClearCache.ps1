#Script created by Bastiaan Geijtenbeek on the 8th of July, 2022 (out of sheer lazyness). 
#Troubleshooting app deployments regularly this entire process has become too much of a repetitive task, yay automation!
#
#Script removes the Company Portal App cache & GRS, allowing for much faster reinstallation attempts (for required apps especially) via Company Portal.
#Run as admin and make sure you set execution policy to unrestricted!
#
#First we check and create some log folders when not present yet, we set log file path/output and create the writelog function.
#
#Then we start clearing the cache:
#1: Check if Company Portal is opened and close it if true.
#2: Stop Intune Management Extension Service
#3: Delete regkeys that make up part of the Company Portal cache. 
#4: Remove Content/Incoming folder and content.
#5: Remove Content/Staging folder and content.
#6: Remove Content/DetectionScript folder and content.
#7: Start Intune Managament Extension Service
#9: Prompt user to restart Company Portal and Sync (via windows notification)
#
#


########################################################
#SET UP THE LOGS FOR THIS SCRIPT
########################################################

#Check and create log folders
$dirCheck1 = Get-Item "C:\ScriptLogs\" -ErrorAction SilentlyContinue
if ($dirCheck1) {
} else {
    New-Item -Path C:\ -Name ScriptLogs -ItemType Directory
}
$dirCheck2 = Get-Item "C:\ScriptLogs\cpClearCache" -ErrorAction SilentlyContinue
if ($dirCheck2) {
} else {
    New-Item -Path C:\ScriptLogs\ -Name cpClearCache -ItemType Directory
}
Remove-Variable dirCheck1, dirCheck2

#Set log file path/output
$logDate = (Get-Date).toString("yyyyMMdd_HHmmss")
$Logfile = "C:\ScriptLogs\cpClearCache\cpClearCache_Log"+ $logDate +".log"

#Create WriteLog Function
function WriteLog
{
Param ([string]$LogString)
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$LogMessage = "$Stamp $LogString"
Add-content $LogFile -value $LogMessage
}

########################################################
#START EMPTYING THE CACHE
########################################################

#1: Check if Company Portal is opened and close it if true. 
WriteLog "1: Closing Company Portal if currently open.."
$companyPortal = Get-Process "CompanyPortal" -ErrorAction SilentlyContinue
if ($companyPortal) {
    $companyPortal | Stop-Process -Force
    Start-Sleep -s 1
    WriteLog "1: App was open. Closed now. Proceeding to phase 2.."
    } else {
    WriteLog "1: App was not open. Proceeding to phase 2.."
    }
Remove-Variable companyPortal

#2: Stop Intune Managament Extension Service
WriteLog "2: Stopping IntuneManagementExtension Service"
Stop-Service -Name IntuneManagementExtension
Start-Sleep -s 6
WriteLog "2: IntuneManagementExtension Service stopped. Proceeding with phase 3.."

#3: Delete regkeys that make up part of the Company Portal cache.
WriteLog "3: Deleting regkeys that are part of the Company Portal cache.."
$allSubKeys = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
#If value is not equal to NULL, delete all subkeys 
if ($allSubKeys) {
    Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting"| Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    #See if it has worked and write to host
    Start-Sleep -Seconds 2
    $regKeyDelete = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
    if ($regKeyDelete) {
        WriteLog "3: Keys were found but failed to delete. Please manually check HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ and delete all subkeys. Proceeding to phase 4.."
        Remove-Variable regKeyDelete
    } else {
        WriteLog "3: Keys were found and successfully deleted. Proceeding to phase 4.." 
    }
} else {
    WriteLog "3: No keys were found. Proceeding with phase 4.."
}
Remove-Variable allSubKeys 

#4: Remove Content\Incoming folder.
WriteLog "4: Remove the Incoming folder that is part of the Company Portal cache.."
$checkIncoming = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming' -ErrorAction SilentlyContinue
if ($checkIncoming) {
    #take ownership for admin group
    takeown /a /r /d Y /f "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming"
    #First remove items, then remove the folder
    Get-ChildItem "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming" -Include *.* -Recurse | ForEach  { $_.Delete()}
    Remove-Item -Path "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming" -Force -Recurse -ErrorAction SilentlyContinue    
    Start-Sleep -s 3
    #has it worked?
    $checkIncoming = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming' -ErrorAction SilentlyContinue
    if ($checkIncoming) {
        WriteLog "4: The Incoming folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming folder for manual deletion. Proceeding with phase 5.." 
    } else {
        WriteLog "4: The Incoming folder was found and successfully deleted. Proceeding with phase 5.." 
    }
} else {
    WriteLog "4: The Incoming folder was not found, no deletion required. Proceeding with phase 5.."
}
Remove-Variable checkIncoming 

#5: Remove Content\Staging folder.
WriteLog "5: Remove the Staging folder that is part of the Company Portal cache.."
$checkStaging = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging' -ErrorAction SilentlyContinue
if ($checkStaging) {
    #take ownership for admin group
    takeown /a /r /d Y /f "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging"
    #First remove items, then remove the folder
    Get-ChildItem "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging" -Include *.* -Recurse | ForEach  { $_.Delete()}
    Remove-Item -Path "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging" -Force -Recurse -ErrorAction SilentlyContinue    
    Start-Sleep -s 3
    #has it worked?
    $checkStaging = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging' -ErrorAction SilentlyContinue
    if ($checkStaging) {
        WriteLog "5: The Staging folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging folder for manual deletion. Proceeding with phase 6.." 
    } else {
        WriteLog "5: The Staging folder was found and successfully deleted. Proceeding with phase 6.." 
    }
} else {
    WriteLog "5: Staging folder not found, no deletion required. Proceeding with phase 6.."
}
Remove-Variable checkStaging

#6: Remove Content\DetectionScripts folder.
WriteLog "6: Remove the DetectionScripts folder that is part of the Company Portal cache.."
$checkDetectionScripts = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts' -ErrorAction SilentlyContinue
if ($checkDetectionScripts) {
    #take ownership for admin group
    takeown /a /r /d Y /f "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts"
    #First remove items, then remove the folder
    Get-ChildItem "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts" -Include *.* -Recurse | ForEach  { $_.Delete()}
    Remove-Item -Path "C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts" -Force -ErrorAction SilentlyContinue    
    Start-Sleep -s 3
    #has it worked?
    $checkDetectionScripts = Get-Item 'C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts' -ErrorAction SilentlyContinue
    if ($checkDetectionScripts) {
        WriteLog "6: The DetectionScripts folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts folder for manual deletion. Proceeding with phase 7.." 
    } else {
        WriteLog "6: The DetectionScripts folder was found and successfully deleted. Proceeding with phase 7.." 
    }
} else {
    WriteLog "6: DetectionScript folder not found, no deletion required. Proceeding with phase 7.."
}
Remove-Variable checkDetectionScripts

#7: Start Intune Managament Extension Service
WriteLog "7: Starting IntuneManagementExtension Service"
Start-Service -Name IntuneManagementExtension
Start-Sleep -s 6
WriteLog "7: IntuneManagementExtension Service started. Proceeding with phase 8.."

#8: Prompt user to restart Company Portal and Sync (via windows notification)
[reflection.assembly]::loadwithpartialname('System.Windows.Forms')
[reflection.assembly]::loadwithpartialname('System.Drawing')
$notify = new-object system.windows.forms.notifyicon
$notify.icon = [System.Drawing.SystemIcons]::Information
$notify.visible = $true
$notify.showballoontip(30000,'Company Portal cache cleared','Please start the Company Portal app, click the wheel and sync when option appears.',[system.windows.forms.tooltipicon]::None)

WriteLog "8: Prompted user to re-sync company portal via Windows Notification"
WriteLog "Script finished!"
