<#
.DESCRIPTION
 Script connects to MsGraph and then fetches all registered AutoPilot Device info (more than the default export function from within Intune). It then writes it to a .csv file.
.PARAMETER <inputfile>
When used, this parameter will allow you to import a .txt file containing pre-selected serial numbers. Should contain the entire path & filename.
.PARAMETER <outputfile>
When used, this parameter will allow for changing the default export path & filename. 
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.INPUTS
Import pre-selected serial numbers so script will check only these. Should be a .txt file with every serial number on its own line. Use the inputFile parameter to add.
.OUTPUTS
Export file (.csv) - default location C:\Temp\AutoPilot-Device-Export-$dateStamp.csv (or custom when outputFile parameter is used)
Log file (.log) - will write the transcript of the script to C:\Temp\AutoPilot-Device-Export-$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  04-Nov-2023
  Purpose/Change: Regular export from Intune doesn't contain all the information I require such as groupTag, AssignedUser, etc.
  Prerequisites: Installed powershell modules:

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
.\ExtendedApDeviceExport.ps1 -inputFile 'C:\location\to\inputfile.txt' -outputFile 'C:\location\to\exportfile.csv' -Log
#>

param(
     [Parameter()]
     [string]$inputFile,

     [Parameter()]
     [string]$outputFile,

     [Parameter()]
     [switch]$Log
 )

#Set dateStamp variable
$dateStamp = Get-Date -Format "yyyyMMddHHmm"
#If log parameter was called, write log to
if ($Log.IsPresent){
    Start-Transcript -Path "C:\Temp\AutoPilot-Device-Export-$dateStamp.log" -Force
}

try {
    #If inputFile has been added to install parameter
    if ($inputFile){
        $snPath = $inputFile
        Write-Host "Imported file $snPath for specific device serial numbers"

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
        
        #Get the serial numbers from the text file and loop through them
        $SerialNumbers = Get-Content -Path $snPath
        $devicesnotfoundcount = 0
        $devicesfoundcount = 0

        foreach ($Serial in $SerialNumbers) {
            $device = Get-AutopilotDevice -serial $Serial
            if (!($device)) {
                Write-Host "S/N $Serial could not be found in this tenants AutoPilot Registered devices."
                $devicesnotfoundcount = $devicesnotfoundcount + 1
            }
            else {
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
        }
    }

    #When no inputFile has been added to install parameter, get them all
    else {
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
    }
}

catch {
    Write-Error $_
}

if ($inputFile){
    Write-Host "End of script, $devicesfoundcount device(s) found and added to .csv. $devicesnotfoundcount device(s) from the inputFile has/have not been found in this tenants AutoPilot devices."
}
else {
    Write-Host "End of script, $devicesfoundcount device(s) found and added to .csv."
}

if ($Log.IsPresent) {
    Stop-Transcript
}