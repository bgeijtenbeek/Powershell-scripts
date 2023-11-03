#Define the output .csv file path
$csvFilePath = "C:\Temp\AutoPilot_device_export.csv"
$snPath = "C:\Temp\SerialNumbers.txt"

#Connect to MS Graph
Connect-MgGraph -NoWelcome


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