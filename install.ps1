<#
.SYNOPSIS
  Import or re-import a custom WSL2 distro from a tarball or GitHub release.
.DESCRIPTION
  By default, fetches the latest GitHub release asset (xve-distro.tar) from your artifacts repo and saves it next to this script.
  If you pass `-Local`, it skips the download and uses the local `-TarballPath`.
.PARAMETER DistroName
  Name to register under WSL (default: XVE).
.PARAMETER InstallDir
  Windows path to install the distro's filesystem data (default: $env:USERPROFILE\WSL\XVE).
.PARAMETER TarballPath
  When `-Local` is used, path to the local tarball. Defaults to ".\xve-distro.tar".
.PARAMETER Local
  Switch: if present, skip GitHub download and import directly from `-TarballPath`.
.PARAMETER Token
  Switch: if present, use GITHUB_TOKEN for private releases.
#>
[CmdletBinding()]
param(
    [string]$DistroName  = 'XVE',
    [string]$InstallDir  = "$env:USERPROFILE\WSL\XVE",
    [string]$TarballPath = ".\xve-distro.tar",
    [switch]$Local,
    [switch]$Token
)

# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Warning 'Please run this script as Administrator.'
    exit 1
}

# Determine script folder
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $scriptDir

# Download from GitHub if not local
if (-not $Local) {
    $repo      = 'jonasvanderhaegen-xve/xve-artifacts'
    $assetName = 'xve-distro.tar'
    Write-Host "Fetching latest release from GitHub repo '$repo'..."
    $headers   = @{ 'User-Agent' = 'XVE-Importer' }
    if ($Token) {
        $ghToken = $Env:GITHUB_TOKEN
        if (-not $ghToken) { Write-Error "-UseToken specified but GITHUB_TOKEN not set."; exit 1 }
        $headers.Authorization = "token $ghToken"
    }
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -Headers $headers -ErrorAction Stop
    } catch {
        Write-Error "Failed fetching latest release: $($_.Exception.Message)"
        exit 1
    }
    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) { Write-Error "Asset '$assetName' not found in latest release."; exit 1 }
    $dest  = Join-Path $scriptDir $assetName
    Write-Host "Downloading '$assetName' to '$dest'..."
    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing -Headers $headers -ErrorAction Stop
        $TarballPath = $dest
    } catch {
        Write-Error "Download failed: $($_.Exception.Message)"
        exit 1
    }
} else {
    if (-not (Test-Path $TarballPath)) {
        Write-Error "Local tarball '$TarballPath' not found."
        exit 1
    }
    Write-Host "Using local tarball: $TarballPath"
}

# Import the distro
Write-Host "Importing WSL distro '$DistroName' from '$TarballPath'..."
wsl --import $DistroName $InstallDir $TarballPath --version 2
if ($LASTEXITCODE -eq 0) {
    Write-Host "Done! You can now run: wsl -d $DistroName"
} else {
    Write-Error "WSL import failed with exit code $LASTEXITCODE."
    Pop-Location
    exit 1
}

Pop-Location
