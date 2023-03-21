<#
.SYNOPSIS
    Uninstalls Articulate 360 bundles and their components.

.DESCRIPTION
    This script uninstalls Articulate 360 bundles and their components by closing related processes and running the appropriate uninstall executables. It can be useful in automating the uninstallation process, especially in an enterprise environment.

.PARAMETER None
    This script does not have any parameters.

.EXAMPLE
    .\Uninstall-Articulate360Bundles.ps1

.EXAMPLE
    Run this command from a command prompt to view what its doing with verbose comments
    Powershell.exe -ExecutionPolicy Bypass -nologo -noprofile -Command ". 'C:\Scripts\Uninstall-Articulate360Bundles.ps1'; Uninstall-Articulate360Bundles -Verbose"

.EXAMPLE
    Run this command from a command prompt and it will hide the powershell window. 
    Powershell.exe -ExecutionPolicy Bypass -windowstyle hidden -noninteractive -nologo -noprofile -Command ". 'C:\Scripts\Uninstall-Articulate360Bundles.ps1'; Uninstall-Articulate360Bundles"

.NOTES
    Author: Gary Smith
    Version: 1.0
    Date: 2023-03-21
#>
function Uninstall-Articulate360Bundles {
    [CmdletBinding()]
    param()

    Write-Verbose "Defining Articulate 360 bundle names to uninstall..."
    
    # Define the names of the Articulate 360 bundles to uninstall
    $bundleNames = @(
        "Articulate 360",
        "Articulate Studio 360",
        "Articulate Replay 360",
        "Articulate Storyline 360",
        "Articulate Peek 360"
    )

    Write-Verbose "Defining process names to close before uninstalling the bundles..."
    
    # Define the names of the processes to close before uninstalling the bundles
    $processNames = @(
        "Articulate 360 Desktop App",
        "Articulate 360 Desktop Service",
        "Articulate 360 Installer Service",
        "Quizmaker",
        "Presenter",
        "Replay",
        "Storyline",
        "Engage"
    )

    Write-Verbose "Starting loop to terminate related processes..."
    
    # Loop through the process names and close any running instances
    foreach ($processName in $processNames) {
        Write-Verbose "Attempting to terminate $processName processes..."
        
        # Get all processes with the specified name and stop them forcefully
        Get-Process $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        
        Write-Verbose "Terminated $processName processes if found."
    }

    Write-Verbose "Starting loop to uninstall Articulate 360 bundles..."
    
    # Uninstall each Articulate 360 bundle by running the found uninstall executable and switches
    foreach ($bundleName in $bundleNames) {
        Write-Verbose "Searching for $bundleName uninstall information in the registry..."
        
        # Find the uninstall executable and switches for the bundle using the registry
        $uninstallPaths = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*\").GetEnumerator() | Where-Object { $_.DisplayName -eq $bundleName -and $_.BundleVersion } | Select-Object -ExpandProperty QuietUninstallString

        Write-Verbose "Found uninstall information for $bundleName. Proceeding to loop through uninstall paths..."
        
        # Loop through the found uninstall paths
        foreach ($uninstallPath in $uninstallPaths) {
            Write-Verbose "Extracting the executable path from the uninstall string for $bundleName..."
            
            # Use a regular expression to extract the executable path from the uninstall string
            $executable = $uninstallPath -replace '^"(?<path>.+?)".+$','$1'

            # Check if the executable exists before running it with the switches
            if (Test-Path $executable) {
                Write-Verbose "Executable found. Constructing log file path for $bundleName..."
                
                # Construct the log file path based on
                # Construct the log file path based on the bundle display name
                $logFilePath = Join-Path -Path $env:TEMP -ChildPath "$($bundleName -replace ' ', '_')_Uninstall.log"

                # Start the uninstall process and wait for it to complete
                Write-Verbose "Uninstalling $bundleName..."
                $process = Start-Process -FilePath $($executable) -ArgumentList "/uninstall", "/quiet", "/l*v", $logFilePath -PassThru -Wait
                Write-Verbose "$bundleName successfully uninstalled."

                # Check if a reboot is required based on the process's exit code
                if ($process.ExitCode -eq 3010) {
                    Write-Verbose "Reboot required after uninstalling $bundleName."
                }
            } else {
                Write-Warning "Could not find uninstall executable: $executable"
            }
        }
    }
}
