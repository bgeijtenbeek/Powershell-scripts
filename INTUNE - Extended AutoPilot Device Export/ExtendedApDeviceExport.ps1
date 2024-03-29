﻿<#
.DESCRIPTION
Script connects to MsGraph and then fetches all registered AutoPilot Device info (more than the default export function from within Intune). It then writes it to a .csv file.
.PARAMETER <outputfile>
When used, this parameter will allow for changing the default export path & filename. 
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.OUTPUTS
Export file (.csv) - default location C:\Temp\AutoPilot-Device-Export-$dateStamp.csv (or custom when outputFile parameter is used)
Log file (.log) - will write the transcript of the script to C:\Temp\ScriptLogs\AutoPilot-Device-Export-$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  04-Nov-2023
  Purpose/Change: Regular export from Intune doesn't contain all the information I require such as groupTag, AssignedUser, etc.
  Prerequisites:  Installed powershell modules:

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module WindowsAutopilotIntune -MinimumVersion 5.4.0 -Force
    Install-Module Microsoft.Graph.Groups -Force
    Install-Module Microsoft.Graph.Authentication -Force
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force

    Import-Module WindowsAutopilotIntune -MinimumVersion 5.4
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Identity.DirectoryManagement

.EXAMPLE
.\ExtendedApDeviceExport.ps1
.\ExtendedApDeviceExport.ps1 -Log
.\ExtendedApDeviceExport.ps1 -Log -outputFile 'C:\location\to\exportfile.csv'
#>

param(

    [Parameter()]
    [string]$outputFile,

    [Parameter()]
    [switch]$Log
 )

#Set dateStamp variable
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
#If log parameter was called, write log to
if ($Log.IsPresent){
    Start-Transcript -Path "C:\Temp\ScriptLogs\AutoPilot-Device-Export-$dateStamp.log" -Force
}

try {
    #Set Custom outputfile or else set default path & name.
    if ($outputFile){
        $csvFilePath = $outputFile
        Write-Host "Outputfile (custom): $csvFilePath"
    }
    else {
        $csvFilePath = "C:\Temp\AutoPilot-Device-Export-$dateStamp.csv"
        Write-Host "Outputfile (default): $csvFilePath"
    }

    #Connect to MsGraph
    Write-Host "Connecting to MsGraph.."
    Connect-MgGraph -NoWelcome

    $devices = Get-AutopilotDevice
    $devicesfoundcount = 0

    foreach ($device in $devices) {
        $serialNumber = $device.serialnumber
        $manufacturer = $device.manufacturer
        $systemFamily = $device.systemFamily
        $model = $device.model
        $userAssignment = $device.userPrincipalName
        $deviceAssignedName = $device.displayName
        $groupTag = $device.GroupTag
        $enrollmentState = $device.enrollmentState
        $azureAdDeviceID = $device.azureAdDeviceId

        # Create a custom object for the current data
        $rowData = [PSCustomObject]@{
            SerialNumber = $serialNumber
            Manufacturer = $manufacturer
            SystemFamily = $systemFamily
            Model = $model    
            UserAssigned = $userAssignment
            DeviceAssignedName = $deviceAssignedName
            GroupTag = $groupTag
            EnrollmentState = $enrollmentState
            AzureAdDeviceId = $azureAdDeviceID
        }

        # Append the data to the .csv file
        $rowData | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
        Write-Host "S/N $serialNumber information added to csv.."
        $devicesfoundcount = $devicesfoundcount + 1
    } 
    Write-Host "End of script, $devicesfoundcount device(s) found and added to .csv."
}

catch {
    Write-Error $_
}

if ($Log.IsPresent) {
    Stop-Transcript
}