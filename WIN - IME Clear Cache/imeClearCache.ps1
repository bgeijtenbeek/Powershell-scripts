<#
.DESCRIPTION
Script empties the Company Portal or IME "cache" (regkeys, staging folders, etc) thereby resetting GRS and forcing Company Portal / IME to do a fresh sync. 
Helps when required apps are not coming through because of GRS.
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.PARAMETER <Silent>
Switch that, when added to installation command, prevent a popup message at the end of the script.
.OUTPUTS
Log file (.log) - will write the transcript of the script to C:\Temp\ScriptLogs\IME-ClearCache-$dateStamp.log (when Log parameter is used).
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  04-Nov-2023
  Purpose/Change: Required apps sometime take a long to to install after sync. This is (partly) because of the cache. Emtpying helps required apps to install gaian sooner/quicker.

.EXAMPLE
.\imeClearCache.ps1 -Log -Silent
#>

param(
     [Parameter()]
     [switch]$Log,

     [Parameter()]
     [switch]$Silent,

     [Parameter()]
     [switch]$All,

     [Parameter()]
     [switch]$Apps,

     [Parameter()]
     [switch]$Scripts

 )

#Set dateStamp variable
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
#If log parameter was called, write log to
if ($Log.IsPresent){
    Start-Transcript -Path "C:\Temp\ScriptLogs\IME-ClearCache-$dateStamp.log" -Force
}

Try {

    #Check if Company Portal is opened and close it if true. 
    Write-Host "Closing Company Portal if currently open.."
    $companyPortal = Get-Process "CompanyPortal" -ErrorAction SilentlyContinue
    if ($companyPortal) {
        $companyPortal | Stop-Process -Force
        Start-Sleep -s 1
        Write-Host "- App was open. Closed now. Proceeding.."
        } else {
        Write-Host "- App was not open, no need for closing app in advance. Proceeding.."
        }
    Remove-Variable companyPortal

    #Stop Intune Managament Extension Service
    Write-Host "Stopping IntuneManagementExtension Service"
    Stop-Service -Name IntuneManagementExtension
    Start-Sleep -s 6
    Write-Host "- IntuneManagementExtension Service stopped. Proceeding.."

    #Clear Apps cache when parameters are present
    if ($All.IsPresent -or $Apps.IsPresent){
        
        ########################################################
        #START EMPTYING THE APPS CACHE
        ########################################################
        Write-Host "Deleting app cache.."

        #Delete regkeys that make up part of the Company Portal cache.
        Write-Host "Deleting regkeys that are part of the Company Portal cache.."
        $allSubKeys = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
        #If value is not equal to NULL, delete all subkeys 
        if ($allSubKeys) {
            Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting"| Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            #See if it has worked and write to host
            Start-Sleep -Seconds 2
            $regKeyDelete = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
            if ($regKeyDelete) {
                Write-Host "- Keys were found but failed to delete. Please manually check HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ and delete all subkeys. Proceeding.."
                Remove-Variable regKeyDelete
            } else {
                Write-Host "- Keys were found and successfully deleted. Proceeding.." 
            }
        } else {
            Write-Host "- No keys were found. Proceeding.."
        }
        Remove-Variable allSubKeys 
  
        #Remove Content\Incoming folder.
        Write-Host "Remove the Content\Incoming folder that is part of the Company Portal cache.."
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
                Write-Host "- The Content\Incoming folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming folder for manual deletion. Proceeding.." 
            } else {
                Write-Host "- The Content\Incoming folder was found and successfully deleted. Proceeding.." 
            }
        } else {
            Write-Host "- The Content\Incoming folder was not found, no deletion required. Proceeding.."
        }
        Remove-Variable checkIncoming 

        #Remove Content\Staging folder.
        Write-Host "Remove the Content\Staging folder that is part of the Company Portal cache.."
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
                Write-Host "- The Content\Staging folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging folder for manual deletion. Proceeding.." 
            } else {
                Write-Host "- The Content\Staging folder was found and successfully deleted. Proceeding.." 
            }
        } else {
            Write-Host "- Content\Staging folder not found, no deletion required. Proceeding.."
        }
        Remove-Variable checkStaging

        #Remove Content\DetectionScripts folder.
        Write-Host "Remove the Content\DetectionScripts folder that is part of the Company Portal cache.."
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
                Write-Host "- The Content\DetectionScripts folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts folder for manual deletion. Proceeding.." 
            } else {
                Write-Host "- The Content\DetectionScripts folder was found and successfully deleted. Proceeding.." 
            }
        } else {
            Write-Host "- Content\DetectionScripts folder not found, no deletion required. Proceeding.."
        }
        Remove-Variable checkDetectionScripts
        Write-Host "Finished deleting everything related to apps."
    }

    #Clear Scripts cache when parameters are present
    if ($All.IsPresent -or $Scripts.IsPresent){ 

        ########################################################
        #START EMPTYING THE SCRIPTS CACHE
        ########################################################
        Write-Host "Deleting scripts cache.."

        #Delete regkeys that make up part of the Company Portal cache.
        Write-Host "Deleting regkeys that are part of the Company Portal cache.."
        $allScriptSubKeys = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\ -ErrorAction SilentlyContinue
        #If value is not equal to NULL, delete all subkeys 
        if ($allScriptSubKeys) {
            Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\ | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            #See if it has worked and write to host
            Start-Sleep -Seconds 2
            $scriptRegKeyDelete = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\ -ErrorAction SilentlyContinue
            if ($scriptRegKeyDelete) {
                Write-Host "- Keys were found but failed to delete. Please manually check HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies\ and delete all subkeys. Proceeding.."
                Remove-Variable scriptRegKeyDelete
            } else {
                Write-Host "- Keys were found and successfully deleted. Proceeding.." 
            }
        } else {
            Write-Host "- No keys were found. Proceeding.."
        }
        Remove-Variable allScriptSubKeys 
        Write-Host "Finished deleting everything related to scripts."
    }

    #Start Intune Managament Extension Service
    Write-Host "Starting IntuneManagementExtension Service"
    Start-Service -Name IntuneManagementExtension
    Start-Sleep -s 6
    Write-Host "- IntuneManagementExtension Service started."

    if (!($Silent.IsPresent)){
        #Show popup that script is done
        Write-Host "Script finished, showing popup."
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("The operation was completed. Please attempt another synchronization to fetch the latest data/apps/scripts from Intune.",0,"IntuneManagementExtension - ClearCache",0x0)
    }
    Write-Host "End of Script. Catch & exit."
}

Catch {
    $ErrorText = "Error: $($_.Exception.Message)"
    Write-Host $ErrorText
}

# Exit the script or take other appropriate action
if (!($ErrorText)) {
    Write-Host "Exit code 0: No Error detected."
    if ($Log.IsPresent){
        Stop-Transcript
    }
    Exit 0
}
else {
    Write-Host "Exit code 1: Error detected."
    if ($Log.IsPresent){
        Stop-Transcript
    }
    exit 1
}