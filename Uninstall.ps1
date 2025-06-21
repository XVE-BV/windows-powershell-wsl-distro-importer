<## Remove.ps1 ##>
<#
.SYNOPSIS
  Unregister (remove) a WSL2 distro by name.
.PARAMETER DistroName
  Name of the distro to unregister (default: XVE).
#>
param(
    [string]$DistroName = 'XVE'
)

# Ensure running as Administrator
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning 'Please run this script as Administrator.'
    Exit 1
}

# Check if distro exists
$distroList = wsl -l -q
If ($distroList -notcontains $DistroName) {
    Write-Warning "Distro '$DistroName' is not registered."
    Exit 1
}

# Shutdown and unregister
Write-Host "Stopping WSL and unregistering '$DistroName'..."
wsl --shutdown
wsl --unregister $DistroName

Write-Host "Distro '$DistroName' has been unregistered and removed."