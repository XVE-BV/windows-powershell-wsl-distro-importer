<#
.SYNOPSIS
  Import or re-import a custom WSL2 distro from a tarball or GitHub release, and enable Docker Desktop WSL integration.
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
Write-Host "Distro '$DistroName' has been registered."

Pop-Location

# --- Enable Docker Desktop WSL Integration for XVE ---
$roaming = Join-Path $Env:APPDATA 'Docker'
# Build array of possible settings file paths
$paths = @(
    Join-Path $roaming 'settings.json';
    Join-Path $roaming 'settings-store.json'
)
$settingsPath = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsPath) {
    Write-Warning "Docker Desktop settings not found at expected locations:`n  $($paths -join '`n  ')"
    return
}

# Load file and strip comments
try {
    $raw = Get-Content $settingsPath -Raw
    $clean = $raw -replace '(?m)//.*$','' -replace '(?s)/\*.*?\*/',''
    $json = $clean | ConvertFrom-Json
} catch {
    Write-Warning "Could not parse JSON from $settingsPath. Attempting lenient load."
    try {
        $json = Get-Content $settingsPath -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Warning "Failed to load settings JSON. Skipping integration enable."
        return
    }
}

# Enable integration
$json.wslEngineEnabled = $true

# Determine list key
if ($json.PSObject.Properties.Name -contains 'wslDistros') {
    $listKey = 'wslDistros'
} elseif ($json.PSObject.Properties.Name -contains 'enabledWSLDistros') {
    $listKey = 'enabledWSLDistros'
} else {
    Write-Warning "Could not find expected list key in $settingsPath"
    return
}

# Add distro
$existing = @($json.$listKey)
if ($existing -notcontains $DistroName) {
    $existing += $DistroName
    $json.$listKey = $existing
    $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "✅ Added '$DistroName' to Docker Desktop WSL integration in $(Split-Path $settingsPath -Leaf)."
} else {
    Write-Host "'$DistroName' already in integration list."
}

# Restart Docker Desktop
Write-Host "🔄 Restarting Docker Desktop..."
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ErrorAction SilentlyContinue
