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

The script contains 1 string parameter and 1 switch parameter:
-outputFile : contains a custom .csv export path. Default (when parameter is not used) path is "C:\Temp\AutoPilot-Device-Export-$dateStamp.csv"
-Log : Switch parameter, when used will create a transcript of the process to "C:\Temp\ScriptLogs\AutoPilot-Device-Export-$dateStamp.log".


Examples:
.\ExtendedApDeviceExport.ps1
.\ExtendedApDeviceExport.ps1 -Log -outputFile 'C:\location\to\exportfile.csv'

