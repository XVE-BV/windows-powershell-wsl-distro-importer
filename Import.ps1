<#
.SYNOPSIS
  Import or re-import a custom WSL2 distro from a tarball or GitHub release.
.DESCRIPTION
  By default, fetches the latest GitHub release asset (xve-distro.tar)  
  from your artifacts repo and saves it next to this script.  
  If you pass `-Local`, it skips the download and uses the local `-TarballPath`.
.PARAMETER DistroName
  Name to register under WSL (default: XVE).
.PARAMETER InstallDir
  Windows path to install the distro's filesystem data (default: $env:USERPROFILE\WSL\XVE).
.PARAMETER TarballPath
  When `-Local` is used, path to the local tarball. Defaults to ".\xve-distro.tar".
.PARAMETER Local
  Switch: if present, skip GitHub download and import directly from `-TarballPath`.
#>
[CmdletBinding()]
param(
    [string]$DistroName  = 'XVE',
    [string]$InstallDir  = "$env:USERPROFILE\WSL\XVE",
    [string]$TarballPath = ".\xve-distro.tar",
    [switch]$Local
)

# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning 'Please run this script as Administrator.'
    exit 1
}

# Determine script folder
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $scriptDir

if (-not $Local) {
    # Download from GitHub, handling “no releases yet” as a 404
    $repo      = 'your-org/xve-artifacts'   # ← replace with your actual owner/repo
    $assetName = 'xve-distro.tar'

    Write-Host "Fetching latest release from GitHub repo '$repo'…"
    try {
        $release = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$repo/releases/latest" `
            -UseBasicParsing -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Warning "No releases found in '$repo'."
            Write-Host  "Publish a release on GitHub or rerun with -Local to use a local tarball."
            exit 1
        }
        else {
            Write-Error "Error fetching release metadata: $_"
            exit 1
        }
    }

    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) {
        Write-Error "Release does not contain asset '$assetName'."
        exit 1
    }

    $downloadUrl = $asset.browser_download_url
    $destPath    = Join-Path $scriptDir $assetName
    Write-Host "Downloading '$assetName' to '$destPath'…"
    try {
        Invoke-WebRequest `
            -Uri $downloadUrl `
            -OutFile $destPath `
            -UseBasicParsing `
            -Headers @{ 'User-Agent' = 'XVE-Importer' } `
            -ErrorAction Stop
    }
    catch {
        Write-Error "Download failed: $_"
        exit 1
    }

    $TarballPath = $destPath
}
else {
    # Use a local tarball
    if (-not (Test-Path $TarballPath)) {
        Write-Error "Local tarball '$TarballPath' not found."
        exit 1
    }
    Write-Host "Using local tarball: $TarballPath"
}

# Unregister existing distro if present
$existing = wsl --list --quiet
if ($existing -contains $DistroName) {
    Write-Warning "Distro '$DistroName' already exists. Replace? (y/N)"
    $ans = Read-Host
    if ($ans -notin 'y','Y') {
        Write-Host "Import cancelled."
        exit 0
    }
    Write-Host "Unregistering existing distro…"
    wsl --unregister $DistroName
}

# Shutdown WSL
Write-Host "Stopping all WSL distros…"
wsl --shutdown

# Prepare install directory
Write-Host "Ensuring install directory: $InstallDir"
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Import the distro
Write-Host "Importing WSL distro '$DistroName' from '$TarballPath'…"
wsl --import $DistroName $InstallDir $TarballPath --version 2

Write-Host "`nDone! You can now run: wsl -d $DistroName"
Pop-Location
