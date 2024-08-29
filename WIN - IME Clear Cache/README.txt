###################
Usage info
###################

Script clears the Company Portal / IntuneManagementExtension cache. This can be useful in cases where installfiles get stuck in the staging phase or when a required app is in GRS mode (not responding to sync so no way of "forcing" the installer to run again). Same goes for scripts that, once run, don't do anything anymore.
When resyncing after the script is done it will force Intune to do the detection from a clean-slate perspective and check & run everything as if it's the first time.
It will do so for ALL USERS!

This script requires no preinstalled modules and it needs to be run by an admin account.

The script:
- Kills Company Portal when open.
- Stops the IntuneManagementExtension service.
-- When Apps are targeted:
- Deletes all the regkeys that contain the install status of apps
- Takes ownership of the incoming, staging and detectionScripts folder and deletes them.
-- When Scripts are targeted:
- Deletes all the regkeys that contain the run status of scripts
- Restarts the IntuneManagementExtension service.

There are 2 switches that can be used in conjunction with this script:
-Log : Writes a transcript of the process to C:\Temp\ScriptLogs\IME-ClearCache-<datestamp>.log
-Silent : This will disable a windows popup that usually shows when the script is finished. Ideal for remote usage.
-All : Will select both apps & script statuses to be purged
-Apps : Will select app statuses to be purged
-Scripts : Will select script statuses to be purged

Examples:
.\imeClearCache.ps1
.\imeClearCache.ps1 -Log -Silent
.\imeClearCache.ps1 -Log -Silent -Apps
.\imeClearCache.ps1 -Log -Silent -All


