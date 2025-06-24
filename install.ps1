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

if (-not $Local) {
    # Download latest release from GitHub (requires a PAT if private)
    $repo      = 'jonasvanderhaegen-xve/xve-artifacts'
    $assetName = 'xve-distro.tar'
    Write-Host "Fetching latest release from GitHub repo '$repo'..."

    $headers = @{ 'User-Agent' = 'XVE-Importer' }
    if ($Token) {
        $ghToken = $Env:GITHUB_TOKEN
        if (-not $ghToken) {
            Write-Error "-UseToken specified but GITHUB_TOKEN not set; cannot authenticate."
            exit 1
        }
        $headers.Authorization = "token $ghToken"
    }

    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -Headers $headers -ErrorAction Stop
    } catch {
        Write-Error "Failed to fetch latest release: $($_.Exception.Response.Content)"
        exit 1
    }

    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) {
        Write-Error "Latest release does not contain asset '$assetName'."
        exit 1
    }

    $downloadUrl = $asset.browser_download_url
    $destPath    = Join-Path $scriptDir $assetName
    Write-Host "Downloading '$assetName' to '$destPath'..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing -Headers $headers -ErrorAction Stop
    } catch {
        Write-Error "Download failed: $_"
        exit 1
    }

    $TarballPath = $destPath
} else {
    # Use a local tarball
    if (-not (Test-Path $TarballPath)) {
        Write-Error "Local tarball '$TarballPath' not found."
        exit 1
    }
    Write-Host "Using local tarball: $TarballPath"
}

# Import the distro
Write-Host "Importing WSL distro '$DistroName' from '$TarballPath'…"
wsl --import $DistroName $InstallDir $TarballPath --version 2

Write-Host "`nDone! You can now run: wsl -d $DistroName"
Pop-Location

# --- Enable Docker Desktop WSL Integration for XVE ---
# Path to Docker Desktop settings
$settingsPath = Join-Path $Env:APPDATA "Docker\settings.json"

# Load & parse settings.json
if (Test-Path $settingsPath) {
    $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    Throw "Could not find Docker Desktop settings at $settingsPath"
}

# Ensure WSL integration is enabled globally
$json.wslEngineEnabled = $true

# Determine list key for distros
if ($json.PSObject.Properties.Name -contains 'wslDistros') {
    $listKey = 'wslDistros'
} elseif ($json.PSObject.Properties.Name -contains 'enabledWSLDistros') {
    $listKey = 'enabledWSLDistros'
} else {
    Throw "Could not find expected WSL-integration list key in settings.json"
}

# Add XVE if not present
$distros = @($json.$listKey)
if ($distros -notcontains $DistroName) {
    $distros += $DistroName
    $json.$listKey = $distros
    # Write updated settings
    $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "✅ Added '$DistroName' to Docker Desktop WSL integration list."
} else {
    Write-Host "'$DistroName' already present in Docker Desktop WSL integration."
}

# Restart Docker Desktop to apply changes
Write-Host "🔄 Restarting Docker Desktop..."
Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
