###################
Usage info
###################

Script gets the local Bitlocker status and writes/appends the info to an Azure Table.
It does so for volumes C:, D: and E: (when they exist). It uses the manage-bde -status <drive> command to fetch the data and then some powershell magic to filter/grab the data we need for the table.

This script requires some powershell modules but installs them as well when they are not present on the machine:

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Az -AllowClobber -Force
    Install-Module AzTable -Force

Also, make sure you have an Azure Table ready to go. 
Hardcode the following variables down in step 2 of the script or use the custom install parameters to pre-fill them from the command line if you would like:

    $StorageAccountName = ""
    $TableName = ""
    $StorageAccountKey = ""

There are 3 string parameters and 1 switch that can be used in conjunction with this script:

-SAN : String parameter, contains the Storage Account Name (for the Azure Table)
-TN : String parameter, contains the Table Name (for the Azure Table)
-SAK : String parameter, contains the Storage Account Key (for the Azure Table)
-Log : Switch parameter, writes a transcript of the process to C:\Temp\ScriptLogs\BitLockerStatus_ToAzureTable_$dateStamp.log

The script must be run with admin privileges.

Examples:
.\Get-BitlockerStatusAndExportToAzureTable.ps1
.\Get-BitlockerStatusAndExportToAzureTable.ps1 -Log
.\Get-BitlockerStatusAndExportToAzureTable.ps1 -Log -SAN "<yourstorageaccountname>" -TN "<yourtablename>" -SAK "<yourstorageaccountkey>"
