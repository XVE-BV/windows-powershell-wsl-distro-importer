<#
.SYNOPSIS
  Scripts to Import and Unregister a custom WSL2 distro.
#>

<#
.SYNOPSIS
  Import a custom WSL2 distro from a tarball.
.DESCRIPTION
  Shuts down WSL, creates the target folder, and imports the distro.
.PARAMETER DistroName
  Name to register under WSL (default: nginx-wsl).
.PARAMETER InstallDir
  Windows path to install the distro's filesystem data (default: $env:USERPROFILE\\WSL\\nginx-wsl).
.PARAMETER TarballPath
  Path to the exported tarball (default: .\\xve-distro.tar).
#>
param(
    [string]$DistroName   = 'XVE',
    [string]$InstallDir   = "$env:USERPROFILE\WSL\XVE",
    [string]$TarballPath  = ".\xve-distro.tar"
)

# Ensure running as Administrator
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning 'Please run this script as Administrator.'
    Exit 1
}

# Check if distro already exists
$existingDistros = wsl --list --quiet
if ($existingDistros -contains $DistroName) {
    Write-Warning "Distro '$DistroName' already exists. Do you want to replace it? (y/N)"
    $response = Read-Host
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Import cancelled."
        Exit 0
    }
    Write-Host "Unregistering existing distro..."
    wsl --unregister $DistroName
}

# Shutdown any running WSL instances
Write-Host "Stopping all WSL distros..."
wsl --shutdown

# Validate tarball exists
If (-not (Test-Path -Path $TarballPath)) {
    Write-Error "Tarball '$TarballPath' not found."
    Exit 1
}

# Create installation directory
Write-Host "Creating install directory: $InstallDir"
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Import the distro
Write-Host "Importing WSL distro '$DistroName'..."
wsl --import $DistroName $InstallDir $TarballPath --version 2