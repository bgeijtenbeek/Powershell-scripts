#Created by Bastiaan Geijtenbeek, please use and adapt to your own liking.
#Script fetches registered AutoPilot Device information, pretty much how the export function within Intune actually works, only with more information this time..
#
#
#Parameter settings for modular installation down the line
#Remember, to be able to connect to MsGraph you will need the following modules installed:
#
#
#
#
#
#
#
#
#
#
#


param(
     [Parameter()]
     [string]$inputFile,

     [Parameter()]
     [string]$outputFile,

     [Parameter()]
     [switch]$DesktopShortcut,

     [Parameter()]
     [switch]$UserContext,

     [Parameter()]
     [switch]$log
 )

#Set dateStamp variable
$dateStamp = Get-Date -Format "yyyyMMddHHmm"

#If log parameter was called, write log to
if ($log.IsPresent){
    Start-Transcript -Path "C:\Temp\AutoPilot-Device-Export-$dateStamp.log" -Force
}

#If inputFile has been added to install parameter
if ($inputFile.IsPresent){
    $snPath = $inputFile
    Write-Host "Imported file $snPath for specific device serial numbers"

    if ($outputFile.IsPresent){
        $csvFilePath = $outputFile
        Write-Host "Outputfile (custom): $csvFilePath"
    }
    else (){
        $csvFilePath = "C:\Temp\AutoPilot-Device-Export-$dateStamp.csv"
        Write-Host "Outputfile (default): $csvFilePath"
    }

    #Connect to MsGraph
    Connect-MgGraph -NoWelcome

}

#When no inputFile has been added to install parameter, get them all
else {

}




#Get the serial numbers from the text file and loop through them
$SerialNumbers = Get-Content -Path $snPath

foreach ($Serial in $SerialNumbers) {
    $device = Get-AutopilotDevice -serial $Serial
    $serialNumber = $device.serialnumber
    $enrollmentState = $device.enrollmentState
    $displayName = $device.displayName
    $groupTag = $device.GroupTag
    $userAssignment = $device.userPrincipalName

    # Create a custom object for the current data
    $rowData = [PSCustomObject]@{
        SerialNumber = $serialNumber
        EnrollmentState = $enrollmentState
        DisplayName = $displayName
        GroupTag = $groupTag
        UserAssigned = $userAssignment
    }
    # Append the data to the .csv file
    $rowData | Export-Csv -Path $csvFilePath -Append -NoTypeInformation
    Write-Host "S/N $serialNumber added to csv..."
}
Write-Host "END OF SCRIPT!"