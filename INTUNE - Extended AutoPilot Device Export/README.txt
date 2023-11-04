###################
Usage info
###################

Script uses MS Graph to connect to Intune And fetch the registered AutoPilot devices. 
It gets more information than the regular built-in Intune export.

You can install & import them via these commands:
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module WindowsAutopilotIntune -MinimumVersion 5.4.0 -Force
    Install-Module Microsoft.Graph.Groups -Force
    Install-Module Microsoft.Graph.Authentication -Force
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force

    Import-Module WindowsAutopilotIntune -MinimumVersion 5.4
    Import-Module Microsoft.Graph.Groups
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Identity.DirectoryManagement

The script writes the output to "C:\Temp\AutoPilot-Device-Export-$dateStamp.csv".
It can be customized using the -outputFile parameter.

It als contains the option to import a .txt file with a pre-selection of serialnumbers to only look for these devices.
Create a .txt file with serial numbers (one-per-line) and target it with the script -inputFile parameter.

You can turn on logging by calling the -Log switch parameter. 
It will write the transcript to "C:\Temp\AutoPilot-Device-Export-$dateStamp.log".

Examples:
.\ExtendedApDeviceExport.ps1
.\ExtendedApDeviceExport.ps1 -inputFile 'C:\location\to\inputfile.txt' -outputFile 'C:\location\to\exportfile.csv' -Log

