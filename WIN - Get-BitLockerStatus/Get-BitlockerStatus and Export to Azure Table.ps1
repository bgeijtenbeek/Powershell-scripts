﻿<#
.DESCRIPTION
 Script collects local BitLocker Data and exports/appends it into an Azure Storage Table.
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.OUTPUTS
Export file (Azure Table)
Log file (.log) - will write the transcript of the script to C:\Temp\Get-BitLockerStatus_ToAzureTable_$dateStamp.txt (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  18-Nov-2023
  Purpose/Change: Export Local Bitlocker Data to Azure Table
  Prerequisites: Installed powershell modules (will install through script when not installed yet):

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Az -AllowClobber -Force
    Install-Module AzTable -Force
.EXAMPLE
.\Get-BitlockerStatus and Export to Azure Table.ps1
.\Get-BitlockerStatus and Export to Azure Table.ps1 -Log
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

param(
     [Parameter()]
     [switch]$Log
 )

$dateStamp = Get-Date -Format "yyyyMMdd_HHmm"

if ($Log.IsPresent) {
    Start-Transcript -Path "C:\Temp\Get-BitLockerStatus_ToAzureTable_$dateStamp.txt" -NoClobber
}

try {
    
    # 1. Check if required Powershell modules are installed (required). If not, install, otherwise nothing
    if (!(Get-PackageProvider -Name Nuget -ErrorAction SilentlyContinue)) {
        Write-Host "NuGet Package Provider not found, installing.."
        Install-PackageProvider -Name NuGet -Force
    }
    else { Write-Host "NuGet Package Provider already installed."}  

    if (!(Get-Module -ListAvailable -Name Az.Storage -ErrorAction SilentlyContinue)) {
        Write-Host "Az Module not found, installing.."
        Install-Module -Name Az -AllowClobber -Force
    }  
    else { Write-Host "Az Module already installed."}  
        
    if (!(Get-Module -ListAvailable -Name AzTable -ErrorAction SilentlyContinue)) {
        Write-Host "AzTable Module not found, installing.."
        Install-Module AzTable -Force
    } 
    else { Write-Host "AzTable Module already installed."}  

    # 2. Define variables for connection
    Write-Host "Defining variables..." 
    $StorageAccountName = ""
    $TableName = "assets"
    $StorageAccountKey = ""
    $PartitionKey = "BitlockerData"

    # 3. Create a new Azure Storage context
    Write-Host "Creating Azure Storage context..."
    $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $Table = (Get-AZStorageTable -Name $TableName -Context $Context).CloudTable

    # 4. Fetch Data
    $hostName = hostname
    $BitlockerStatus = manage-bde -status

    # 5. Manipulate data 
    
    #Filter on different volumes????

    #Get raw seperate info
    $VolumeSizeRaw = $BitlockerStatus | findstr "Size"
    $BitlockerVersionRaw = $BitlockerStatus | findstr "Version"
    $ConversionStatusRaw = $BitlockerStatus | findstr "Conversion"
    $PercentageEncryptedRaw = $BitlockerStatus | findstr "Percentage"
    $EncryptionMethodRaw = $BitlockerStatus | findstr "Method"
    $ProtectionStatusRaw = $BitlockerStatus | findstr "Protection"
    #$LockStatusRaw = $BitlockerStatus | findstr "Lock"
    #$KeyProtectorsRaw = $BitlockerStatus | findstr "Key"

    #Trim unwanted raw info
    $VolumeSize = ($VolumeSizeRaw.Replace("Size: ", "").TRIM())
    $BitlockerVersion = ($BitlockerVersionRaw.Replace("BitLocker Version: ", "").TRIM())
    $ConversionStatus = ($ConversionStatusRaw.Replace("Conversion Status: ", "").TRIM())
    $PercentageEncrypted = ($PercentageEncryptedRaw.Replace("Percentage Encrypted: ", "").TRIM())
    $EncryptionMethod = ($EncryptionMethodRaw.Replace("Encryption Method: ", "").TRIM())
    $ProtectionStatus = ($ProtectionStatusRaw.Replace("Protection Status: ", "").TRIM())
    #$LockStatus = ($LockStatusRaw.Replace("Lock Status: ", "").TRIM())
    #$KeyProtectors = ($KeyProtectorsRaw.Replace("Key Protectors: ", "").TRIM())

    # 6. Write info to database
    Write-Host "Writing information to Azure Table database..."
    Add-AzTableRow `
        -table $Table `
        -partitionKey $PartitionKey `
        -rowKey ([guid]::NewGuid().toString()) -property @{'DateTime' = $dateStamp;'Device' = $hostName;'VolumeSize' = $VolumeSize;'BitlockerVersion' = $BitlockerVersion;'ConversionStatus' = $ConversionStatus;'PercentageEncrypted' = $PercentageEncrypted;'EncryptionMethod' = $EncryptionMethod;'ProtectionStatus' = $ProtectionStatus } | Out-Null
        Write-Host "End of script. Catch & exit"
}

catch {
    $ErrorText = "Error: $($_.Exception.Message)"
    Write-Host $ErrorText
}

# Exit the script or take other appropriate action
if (!($ErrorText)) {
    Write-Host "Exit code 0: No Error detetcted."
    Stop-Transcript
    Exit 0
}
else {
    Write-Host "Exit code 1: Error detetcted."
    Stop-Transcript
    exit 1
}