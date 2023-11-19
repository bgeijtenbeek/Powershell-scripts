<#
.DESCRIPTION
Script collects local BitLocker Data and exports/appends it into an Azure Storage Table.
.PARAMETER <SAN>
Prefill your Storage Account Name via the -SAN string parameter.
.PARAMETER <TN>
Prefill your Table Name via the -TN string parameter.
.PARAMETER <SAK>
Prefill your Storage Account Key via the -SAK string parameter.
.PARAMETER <Log>
Switch that, when added to installation command, will write a log/transcript of the process.
.OUTPUTS
Export file (Azure Table)
Log file (.txt) - will write the transcript of the script to C:\Temp\ScriptLogs\BitLockerStatus_ToAzureTable_$dateStamp.log (when Log parameter is used)
.NOTES
  Version:        1.0
  Author:         bgeijtenbeek
  Creation Date:  19-Nov-2023
  Purpose/Change: Export Local Bitlocker Data to Azure Table
  Prerequisites:  Installed powershell modules (will install through script when not installed yet):

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name Az -AllowClobber -Force
    Install-Module AzTable -Force

Also, make sure you have an Azure Table ready to go. Use the install parameters to enter the required Azure connection details or hardcode them down in step 2 of the script:

    $StorageAccountName = ""
    $TableName = ""
    $StorageAccountKey = ""

Must be run with admin privileges.

.EXAMPLE
.\Get-BitlockerStatusAndExportToAzureTable.ps1
.\Get-BitlockerStatusAndExportToAzureTable.ps1 -Log
.\Get-BitlockerStatusAndExportToAzureTable.ps1 -Log -SAN "<yourstorageaccountname>" -TN "<yourtablename>" -SAK "<yourstorageaccountkey>"
#>

param(

    [Parameter()]
    [string]$SAN,

    [Parameter()]
    [string]$TN,

    [Parameter()]
    [string]$SAK,

    [Parameter()]
    [switch]$Log
 )

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
$dateStamp = Get-Date -Format "yyyyMMddHHmm"

if ($Log.IsPresent) {
    Start-Transcript -Path "C:\Temp\ScriptLogs\BitLockerStatus_ToAzureTable_$dateStamp.log" -NoClobber
}

try {
    
    #####################################################################
    # 1. Check if required Powershell modules are installed (required). 
    # If not, install, otherwise nothing
    #####################################################################
    Write-Host "NuGet Package Provider not found, installing.."
    Install-PackageProvider -Name NuGet -Force

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

    #################################################
    # 2. Define variables for connection
    #################################################
    Write-Host "Defining variables..." 

    #if Storage Account Name variable is already assigned through parameter
    if ($SAN) {
        $StorageAccountName = $SAN
    }
    #when not using the parameter, set variable (hardcode) here.
    else {
        $StorageAccountName = ""
    }

    #if Table Name variable is already assigned through parameter
    if ($TN) {
        $TableName = $TN
    }
    #when not using the parameter, set variable (hardcode) here.
    else {
        $TableName = ""
    }
    
    #if Storage Account Key variable is already assigned through parameter
    if ($SAK) {
        $StorageAccountKey = $SAK
    }
    #when not using the parameter, set variable (hardcode) here.
    else {
        $StorageAccountKey = ""
    }

    $PartitionKey = "BitlockerData"

    #check if variables are present, otherwise exit script
    if(!($StorageAccountName)) {
        $exitError = "yes"
        Write-Host "Error: Storage Account Name variable is NULL."
    }
    if(!($TableName)) {
        $exitError = "yes"
        Write-Host "Error: Table Name variable is NULL."
    }
    if(!($StorageAccountKey)) {
        $exitError = "yes"
        Write-Host "Error: Storage Account Key variable is NULL."
    }
    if ($exitError) {
        Write-Host "Do not have all the connection details for making the Azure Table connection. Exiting.."
        if ($Log.IsPresent){
            Stop-Transcript
        }
        Exit 1
    }

    #############################################
    # 3. Create a new Azure Storage context
    #############################################
    Write-Host "Creating Azure Storage context..."
    $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $Table = (Get-AZStorageTable -Name $TableName -Context $Context).CloudTable

    ##############################
    # 4. Fetch Data / Manipulate
    ##############################
    $hostName = hostname

    #Get info for Drive C: (if exists)
    Write-Host "Trying Drive C:\"
    $BitlockerStatus = manage-bde -status c:
    if (!($BitlockerStatus | findstr "ERROR:")) {
    
        #Get raw seperate info
        $VolumeInfoRaw = "Volume: C:\" 
        $VolumeSizeRaw = $BitlockerStatus | findstr "Size"
        $BitlockerVersionRaw = $BitlockerStatus | findstr "Version"
        $ConversionStatusRaw = $BitlockerStatus | findstr "Conversion"
        $PercentageEncryptedRaw = $BitlockerStatus | findstr "Percentage"
        $EncryptionMethodRaw = $BitlockerStatus | findstr "Method"
        $ProtectionStatusRaw = $BitlockerStatus | findstr "Protection"
        #$LockStatusRaw = $BitlockerStatus | findstr "Lock"
        #$KeyProtectorsRaw = $BitlockerStatus | findstr "Key"

        #Write raw info to host for log
        Write-Host "Collected local BitLocker Information:"
        Write-Host $VolumeInfoRaw
        Write-Host $VolumeSizeRaw
        Write-Host $BitlockerVersionRaw
        Write-Host $ConversionStatusRaw
        Write-Host $PercentageEncryptedRaw
        Write-Host $EncryptionMethodRaw
        Write-Host $ProtectionStatusRaw

        #Trim unwanted raw info
        $VolumeInfo = ($VolumeInfoRaw.Replace("Volume: ", "").TRIM()) 
        $VolumeSize = ($VolumeSizeRaw.Replace("Size: ", "").TRIM())
        $BitlockerVersion = ($BitlockerVersionRaw.Replace("BitLocker Version: ", "").TRIM())
        $ConversionStatus = ($ConversionStatusRaw.Replace("Conversion Status: ", "").TRIM())
        $PercentageEncrypted = ($PercentageEncryptedRaw.Replace("Percentage Encrypted: ", "").TRIM())
        $EncryptionMethod = ($EncryptionMethodRaw.Replace("Encryption Method: ", "").TRIM())
        $ProtectionStatus = ($ProtectionStatusRaw.Replace("Protection Status: ", "").TRIM())
        #$LockStatus = ($LockStatusRaw.Replace("Lock Status: ", "").TRIM())
        #$KeyProtectors = ($KeyProtectorsRaw.Replace("Key Protectors: ", "").TRIM())

        #Write info to database
        Write-Host "Writing information to Azure Table database..."
        Add-AzTableRow `
            -table $Table `
            -partitionKey $PartitionKey `
            -rowKey ([guid]::NewGuid().toString()) -property @{'DateTime' = $dateStamp;'Device' = $hostName;'Volume' = $VolumeInfo;'VolumeSize' = $VolumeSize;'BitlockerVersion' = $BitlockerVersion;'ConversionStatus' = $ConversionStatus;'PercentageEncrypted' = $PercentageEncrypted;'EncryptionMethod' = $EncryptionMethod;'ProtectionStatus' = $ProtectionStatus } | Out-Null

    }
    else {
        Write-host $BitLockerStatus
    }

    #Get info for Drive D: (if exists)
    Write-Host "Trying drive D:\"
    $BitlockerStatus = manage-bde -status d:
    if (!($BitlockerStatus | findstr "ERROR:")) {
    
        #Get raw seperate info
        $VolumeInfoRaw = "Volume: D:\" 
        $VolumeSizeRaw = $BitlockerStatus | findstr "Size"
        $BitlockerVersionRaw = $BitlockerStatus | findstr "Version"
        $ConversionStatusRaw = $BitlockerStatus | findstr "Conversion"
        $PercentageEncryptedRaw = $BitlockerStatus | findstr "Percentage"
        $EncryptionMethodRaw = $BitlockerStatus | findstr "Method"
        $ProtectionStatusRaw = $BitlockerStatus | findstr "Protection"
        #$LockStatusRaw = $BitlockerStatus | findstr "Lock"
        #$KeyProtectorsRaw = $BitlockerStatus | findstr "Key"

        #Write raw info to host for log
        Write-Host "Collected local BitLocker Information:"
        Write-Host $VolumeInfoRaw
        Write-Host $VolumeSizeRaw
        Write-Host $BitlockerVersionRaw
        Write-Host $ConversionStatusRaw
        Write-Host $PercentageEncryptedRaw
        Write-Host $EncryptionMethodRaw
        Write-Host $ProtectionStatusRaw

        #Trim unwanted raw info
        $VolumeInfo = ($VolumeInfoRaw.Replace("Volume: ", "").TRIM()) 
        $VolumeSize = ($VolumeSizeRaw.Replace("Size: ", "").TRIM())
        $BitlockerVersion = ($BitlockerVersionRaw.Replace("BitLocker Version: ", "").TRIM())
        $ConversionStatus = ($ConversionStatusRaw.Replace("Conversion Status: ", "").TRIM())
        $PercentageEncrypted = ($PercentageEncryptedRaw.Replace("Percentage Encrypted: ", "").TRIM())
        $EncryptionMethod = ($EncryptionMethodRaw.Replace("Encryption Method: ", "").TRIM())
        $ProtectionStatus = ($ProtectionStatusRaw.Replace("Protection Status: ", "").TRIM())
        #$LockStatus = ($LockStatusRaw.Replace("Lock Status: ", "").TRIM())
        #$KeyProtectors = ($KeyProtectorsRaw.Replace("Key Protectors: ", "").TRIM())

        #Write info to database
        Write-Host "Writing information to Azure Table database..."
        Add-AzTableRow `
            -table $Table `
            -partitionKey $PartitionKey `
            -rowKey ([guid]::NewGuid().toString()) -property @{'DateTime' = $dateStamp;'Device' = $hostName;'Volume' = $VolumeInfo;'VolumeSize' = $VolumeSize;'BitlockerVersion' = $BitlockerVersion;'ConversionStatus' = $ConversionStatus;'PercentageEncrypted' = $PercentageEncrypted;'EncryptionMethod' = $EncryptionMethod;'ProtectionStatus' = $ProtectionStatus } | Out-Null

    }
    else {
        Write-host $BitLockerStatus
    }

    #Get info for Drive E: (if exists)
    Write-Host "Trying Drive E:\"
    $BitlockerStatus = manage-bde -status e:
    if (!($BitlockerStatus | findstr "ERROR:")) {
    
        #Get raw seperate info
        $VolumeInfoRaw = "Volume: E:\" 
        $VolumeSizeRaw = $BitlockerStatus | findstr "Size"
        $BitlockerVersionRaw = $BitlockerStatus | findstr "Version"
        $ConversionStatusRaw = $BitlockerStatus | findstr "Conversion"
        $PercentageEncryptedRaw = $BitlockerStatus | findstr "Percentage"
        $EncryptionMethodRaw = $BitlockerStatus | findstr "Method"
        $ProtectionStatusRaw = $BitlockerStatus | findstr "Protection"
        #$LockStatusRaw = $BitlockerStatus | findstr "Lock"
        #$KeyProtectorsRaw = $BitlockerStatus | findstr "Key"

        #Write raw info to host for log
        Write-Host "Collected local BitLocker Information:"
        Write-Host $VolumeInfoRaw
        Write-Host $VolumeSizeRaw
        Write-Host $BitlockerVersionRaw
        Write-Host $ConversionStatusRaw
        Write-Host $PercentageEncryptedRaw
        Write-Host $EncryptionMethodRaw
        Write-Host $ProtectionStatusRaw

        #Trim unwanted raw info
        $VolumeInfo = ($VolumeInfoRaw.Replace("Volume: ", "").TRIM()) 
        $VolumeSize = ($VolumeSizeRaw.Replace("Size: ", "").TRIM())
        $BitlockerVersion = ($BitlockerVersionRaw.Replace("BitLocker Version: ", "").TRIM())
        $ConversionStatus = ($ConversionStatusRaw.Replace("Conversion Status: ", "").TRIM())
        $PercentageEncrypted = ($PercentageEncryptedRaw.Replace("Percentage Encrypted: ", "").TRIM())
        $EncryptionMethod = ($EncryptionMethodRaw.Replace("Encryption Method: ", "").TRIM())
        $ProtectionStatus = ($ProtectionStatusRaw.Replace("Protection Status: ", "").TRIM())
        #$LockStatus = ($LockStatusRaw.Replace("Lock Status: ", "").TRIM())
        #$KeyProtectors = ($KeyProtectorsRaw.Replace("Key Protectors: ", "").TRIM())

        #Write info to database
        Write-Host "Writing information to Azure Table database..."
        Add-AzTableRow `
            -table $Table `
            -partitionKey $PartitionKey `
            -rowKey ([guid]::NewGuid().toString()) -property @{'DateTime' = $dateStamp;'Device' = $hostName;'Volume' = $VolumeInfo;'VolumeSize' = $VolumeSize;'BitlockerVersion' = $BitlockerVersion;'ConversionStatus' = $ConversionStatus;'PercentageEncrypted' = $PercentageEncrypted;'EncryptionMethod' = $EncryptionMethod;'ProtectionStatus' = $ProtectionStatus } | Out-Null

    }
    else {
        Write-host $BitLockerStatus
    }
}

catch {
    $ErrorText = "Error: $($_.Exception.Message)"
    Write-Host $ErrorText
}

# Exit the script or take other appropriate action
if (!($ErrorText)) {
    Write-Host "Exit code 0: No Error detetcted."
    if ($Log.IsPresent) {
        Stop-Transcript
    }
    Exit 0
}
else {
    Write-Host "Exit code 1: Error detetcted."
    if ($Log.IsPresent) {
        Stop-Transcript
    }
    exit 1
}