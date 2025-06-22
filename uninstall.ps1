# Remove.ps1
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
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning 'Please run this script as Administrator.'
    exit 1
}

# Check if distro exists
$distroList = wsl --list --quiet
if ($distroList -notcontains $DistroName) {
    Write-Warning "Distro '$DistroName' is not registered."
    exit 1
}

# Prompt for confirmation
$confirm = Read-Host "Are you sure you want to unregister and delete distro '$DistroName'? (y/N)"
if ($confirm -notin 'y','Y') {
    Write-Host 'Operation cancelled.'
    exit 0
}

# Shutdown and unregister
Write-Host "Stopping WSL and unregistering '$DistroName'..."
wsl --shutdown
wsl --unregister $DistroName

Write-Host "Distro '$DistroName' has been unregistered and removed."
