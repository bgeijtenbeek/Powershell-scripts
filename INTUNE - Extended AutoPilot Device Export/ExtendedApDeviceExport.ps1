#Created by Bastiaan Geijtenbeek, please use and adapt to your own liking.
#Script fetches registered AutoPilot Device information, pretty much how the export function within Intune actually works, only with more information this time..
#
#
#Parameter settings for modular installation down the line
#Remember, to be able to connect to MsGraph you will need the following modules installed:
#
#

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
    if ($inputFile.IsPresent){
        $snPath = $inputFile
        Write-Host "Imported file $snPath for specific device serial numbers"

        #Set Custom outputfile or else set default path & name.
        if ($outputFile.IsPresent){
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

        foreach ($Serial in $SerialNumbers) {
            $device = Get-AutopilotDevice -serial $Serial
            $serialNumber = $device.serialnumber
            $manufacturer = $device.manufacturer
            $systemFamily = $device.systemFamily
            $model = $device.model
            $enrollmentState = $device.enrollmentState
            $deviceName = $device.displayName
            $groupTag = $device.GroupTag
            $userAssignment = $device.userPrincipalName

            # Create a custom object for the current data
            $rowData = [PSCustomObject]@{
                SerialNumber = $serialNumber
                Manufacturer = $manufacturer
                SystemFamily = $systemFamily
                Model = $model    
                EnrollmentState = $enrollmentState
                DeviceName = $deviceName
                GroupTag = $groupTag
                UserAssigned = $userAssignment
            }

            # Append the data to the .csv file
            $rowData | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
            Write-Host "S/N $serialNumber information added to csv.."
        }
    }

    #When no inputFile has been added to install parameter, get them all
    else {
        #Set Custom outputfile or else set default path & name.
        if ($outputFile.IsPresent){
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

        foreach ($device in $devices) {
            $serialNumber = $device.serialnumber
            $manufacturer = $device.manufacturer
            $systemFamily = $device.systemFamily
            $model = $device.model
            $enrollmentState = $device.enrollmentState
            $deviceName = $device.displayName
            $groupTag = $device.GroupTag
            $userAssignment = $device.userPrincipalName

            # Create a custom object for the current data
            $rowData = [PSCustomObject]@{
                SerialNumber = $serialNumber
                Manufacturer = $manufacturer
                SystemFamily = $systemFamily
                Model = $model    
                EnrollmentState = $enrollmentState
                DeviceName = $deviceName
                GroupTag = $groupTag
                UserAssigned = $userAssignment
            }

            # Append the data to the .csv file
            $rowData | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
            Write-Host "S/N $serialNumber information added to csv.."
        }
    }
}

catch {
    Write-Error $_
}

if ($Log.IsPresent) {
    Write-Host "End of script, exiting.."
    Stop-Transcript
}