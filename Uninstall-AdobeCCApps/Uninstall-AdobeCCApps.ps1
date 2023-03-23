<#
.Synopsis
Uninstalls all Adobe Creative Cloud applications installed on the computer.

.Description
This script uninstalls all Adobe Creative Cloud applications that are installed on the computer. It uses AdobeUninstaller.exe to perform the uninstallation. Additionally, if the -UseCleanerTool switch is provided, the script will also use AdobeCreativeCloudCleanerTool.exe to clean up all files associated with Adobe Creative Cloud applications.

.Notes
This script will not remove the license from the Adobe Admin Console/Portal. The script might close more applications than required, and the user should ensure that all syncs have completed and any sync conflicts have been resolved before running this script.

.Parameter UseCleanerTool
Indicates whether the script should also use AdobeCreativeCloudCleanerTool.exe to clean up all files associated with Adobe Creative Cloud applications.

.Parameter AdobeUninstallerPath
Specifies the path to the AdobeUninstaller.exe executable. The default path is 'C:\Scripts\AdobeUninstaller.exe'.

.Parameter AdobeCleanerToolPath
Specifies the path to the AdobeCreativeCloudCleanerTool.exe executable. The default path is 'C:\Scripts\AdobeCreativeCloudCleanerTool.exe'.

.Example
Uninstall-AdobeCCApps -UseCleanerTool

Runs the script and uninstalls all Adobe Creative Cloud applications and cleans up all associated files using AdobeCreativeCloudCleanerTool.exe.

.Example
Uninstall-AdobeCCApps -Verbose

Runs the script and uninstalls all Adobe Creative Cloud applications. Verbose output is displayed.

.NOTES
        Author: Gary Smith
        Version: 1.0
        Date: 2023-03-23

.NOTES
    Scripting Notes: 
    Unable to use 'AdobeUninstaller.exe --list' to generate a list of apps to close. Results are a inconsistant table that is converted into an array.
    Adobe constantly updates CC applications and the where-object command is the best attempt to capture them all. 

#>

function Uninstall-AdobeCCApps {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$UseCleanerTool,
        [string]$AdobeUninstallerPath = 'C:\Scripts\AdobeUninstaller.exe',
        [string]$AdobeCleanerToolPath = 'C:\Scripts\AdobeCreativeCloudCleanerTool.exe'
    )

    # Find and close all Adobe processes
    $retryCount = 0
    while ($retryCount -lt 3) {
        $processes = Get-Process * | Where-Object {$_.CompanyName -match "Adobe" -or $_.Path -match "Adobe"} | Stop-Process -ErrorAction SilentlyContinue
        if ($processes) {
            foreach ($process in $processes) {
                Write-Verbose "Closing $($process.ProcessName) process..."
            }
            $retryCount = 0
        } else {
            $retryCount++
            Start-Sleep -Seconds 1
        }
    }

    if ($retryCount -eq 3) {
        Write-Warning "Unable to close all Adobe processes after 5 attempts. Continuing anyway."
    } else {
        Write-Verbose "All Adobe processes closed."
    }

    # Uninstall Adobe CC apps
    Write-Verbose "Running AdobeUninstaller.exe with --all switch..."
    Start-Process -FilePath $AdobeUninstallerPath -ArgumentList '--all' -Wait -NoNewWindow
    Write-Verbose "Adobe CC apps uninstalled."

    if ($UseCleanerTool) {
        # Run Adobe Creative Cloud Cleaner Tool
        Write-Verbose "Running AdobeCreativeCloudCleanerTool.exe with --removeAll=ALL switch..."
        Start-Process -FilePath $AdobeCleanerToolPath -ArgumentList '--removeAll=ALL' -Wait -NoNewWindow
        Write-Verbose "Adobe CC apps cleaned up using Adobe Creative Cloud Cleaner Tool."
    }
}




# Run the function with the UseCleanerTool switch (optional)
#Powershell.exe -ExecutionPolicy Bypass -nologo -noprofile -Command ". 'C:\Scripts\Uninstall-AdobeCCApps.ps1'; Uninstall-AdobeCCApps -UseCleanerTool -Verbose"