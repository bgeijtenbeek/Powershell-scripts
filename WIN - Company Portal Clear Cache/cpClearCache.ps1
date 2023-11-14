<#
.DESCRIPTION
 Script empties the Company Portal or IME "cache" (regkeys, staging folders, etc) thereby resetting GRS and forcing Company Portal / IME to do a fresh sync. 
 Helps when required apps are not coming through because of GRS.
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.PARAMETER <Silent>
Switch that, when added to installation command, will write a log/transcript of the process.
.OUTPUTS
Log file (.log) - will write the transcript of the script to C:\Temp\CompanyPortal-ClearCache-$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  04-Nov-2023
  Purpose/Change: Required apps sometime take a long to to install after sync. This is (partly) because of the cache. Emtpying helps required apps to install gaian sooner/quicker.

.EXAMPLE
.\cpClearCache.ps1 -Log -Silent
#>

param(
     [Parameter()]
     [switch]$Log,

     [Parameter()]
     [switch]$Silent
 )

#Set dateStamp variable
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
#If log parameter was called, write log to
if ($Log.IsPresent){
    Start-Transcript -Path "C:\Temp\ScriptLogs\CompanyPortal-ClearCache-$dateStamp.log" -Force
}

Try {

    ########################################################
    #START EMPTYING THE CACHE
    ########################################################

    #1: Check if Company Portal is opened and close it if true. 
    Write-Host "1: Closing Company Portal if currently open.."
    $companyPortal = Get-Process "CompanyPortal" -ErrorAction SilentlyContinue
    if ($companyPortal) {
        $companyPortal | Stop-Process -Force
        Start-Sleep -s 1
        Write-Host "1: App was open. Closed now. Proceeding to phase 2.."
        } else {
        Write-Host "1: App was not open. Proceeding to phase 2.."
        }
    Remove-Variable companyPortal

    #2: Stop Intune Managament Extension Service
    Write-Host "2: Stopping IntuneManagementExtension Service"
    Stop-Service -Name IntuneManagementExtension
    Start-Sleep -s 6
    Write-Host "2: IntuneManagementExtension Service stopped. Proceeding with phase 3.."

    #3: Delete regkeys that make up part of the Company Portal cache.
    Write-Host "3: Deleting regkeys that are part of the Company Portal cache.."
    $allSubKeys = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
    #If value is not equal to NULL, delete all subkeys 
    if ($allSubKeys) {
        Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting"| Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        #See if it has worked and write to host
        Start-Sleep -Seconds 2
        $regKeyDelete = Get-ChildItem -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ -Exclude "Reporting" -ErrorAction SilentlyContinue
        if ($regKeyDelete) {
            Write-Host "3: Keys were found but failed to delete. Please manually check HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\ and delete all subkeys. Proceeding to phase 4.."
            Remove-Variable regKeyDelete
        } else {
            Write-Host "3: Keys were found and successfully deleted. Proceeding to phase 4.." 
        }
    } else {
        Write-Host "3: No keys were found. Proceeding with phase 4.."
    }
    Remove-Variable allSubKeys 
  
    #4: Remove Content\Incoming folder.
    Write-Host "4: Remove the Incoming folder that is part of the Company Portal cache.."
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
            Write-Host "4: The Incoming folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Incoming folder for manual deletion. Proceeding with phase 5.." 
        } else {
            Write-Host "4: The Incoming folder was found and successfully deleted. Proceeding with phase 5.." 
        }
    } else {
        Write-Host "4: The Incoming folder was not found, no deletion required. Proceeding with phase 5.."
    }
    Remove-Variable checkIncoming 

    #5: Remove Content\Staging folder.
    Write-Host "5: Remove the Staging folder that is part of the Company Portal cache.."
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
            Write-Host "5: The Staging folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging folder for manual deletion. Proceeding with phase 6.." 
        } else {
            Write-Host "5: The Staging folder was found and successfully deleted. Proceeding with phase 6.." 
        }
    } else {
        Write-Host "5: Staging folder not found, no deletion required. Proceeding with phase 6.."
    }
    Remove-Variable checkStaging

    #6: Remove Content\DetectionScripts folder.
    Write-Host "6: Remove the DetectionScripts folder that is part of the Company Portal cache.."
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
            Write-Host "6: The DetectionScripts folder was found but deletion failed. Please check the C:\Program Files (x86)\Microsoft Intune Management Extension\Content\DetectionScripts folder for manual deletion. Proceeding with phase 7.." 
        } else {
            Write-Host "6: The DetectionScripts folder was found and successfully deleted. Proceeding with phase 7.." 
        }
    } else {
        Write-Host "6: DetectionScript folder not found, no deletion required. Proceeding with phase 7.."
    }
    Remove-Variable checkDetectionScripts

    #7: Start Intune Managament Extension Service
    Write-Host "7: Starting IntuneManagementExtension Service"
    Start-Service -Name IntuneManagementExtension
    Start-Sleep -s 6
    Write-Host "7: IntuneManagementExtension Service started."

    if (!($Silent.IsPresent)){
        #Show popup that script is done
        Write-Host "8: Script finished, showing popup."
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("The operation was completed. Please restart the Company Portal app, click the gear-icon on the bottom left, scroll down and then click 'Sync'",0,"Company Portal - ClearCache",0x0)
    }
    
}

Catch {
    Write-Error $_
}

if ($Log.IsPresent){
    Stop-Transcript
}
