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
    # Download latest release from GitHub
    $repo      = 'jonasvanderhaegen-xve/xve-artifacts'
    $assetName = 'xve-distro.tar'
    Write-Host "Fetching latest release from GitHub repo '$repo'..."
    $headers = @{ 'User-Agent' = 'XVE-Importer' }
    if ($Token) {
        $ghToken = $Env:GITHUB_TOKEN
        if (-not $ghToken) { Write-Error "-UseToken specified but GITHUB_TOKEN not set."; exit 1 }
        $headers.Authorization = "token $ghToken"
    }
    try { $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -UseBasicParsing -Headers $headers -ErrorAction Stop } catch { Write-Error "Failed fetching latest release."; exit 1 }
    $asset = $release.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) { Write-Error "Asset '$assetName' not found."; exit 1 }
    $dest = Join-Path $scriptDir $assetName
    Write-Host "Downloading to '$dest'..."; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing -Headers $headers
    $TarballPath = $dest
} else {
    if (-not (Test-Path $TarballPath)) { Write-Error "Local tarball '$TarballPath' not found."; exit 1 }
    Write-Host "Using local tarball: $TarballPath"
}

# Import the distro
Write-Host "Importing WSL distro '$DistroName'..."
wsl --import $DistroName $InstallDir $TarballPath --version 2
if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL import failed with code $LASTEXITCODE. Aborting integration setup."
    Pop-Location
    exit 1
}
Write-Host "Registered distro '$DistroName'."
Pop-Location

# --- Enable Docker Desktop WSL Integration ---
$base = Join-Path $Env:APPDATA 'Docker'
$files = @(Join-Path $base 'settings.json'; Join-Path $base 'settings-store.json')
$configFile = $files | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $configFile) { Write-Warning "No Docker settings file found."; return }

# Load and clean JSON
$raw = Get-Content $configFile -Raw
$clean = $raw -replace '(?m)//.*$','' -replace '(?s)/\*.*?\*/',''
try { $cfg = $clean | ConvertFrom-Json } catch { Write-Warning "Invalid JSON in $configFile."; return }

# Handle known integration structures
if ($cfg.PSObject.Properties.Name -contains 'wslEngineEnabled') {
    $cfg.wslEngineEnabled = $true
    Write-Host "Enabled WSL engine via 'wslEngineEnabled'."
    $list = 'wslDistros'
} elseif ($cfg.PSObject.Properties.Name -contains 'wslEngineSettings') {
    $cfg.wslEngineSettings.enabled = $true
    Write-Host "Enabled WSL engine via 'wslEngineSettings.enabled'."
    $list = 'wslDistros'
} elseif ($cfg.PSObject.Properties.Name -contains 'wslIntegration') {
    $cfg.wslIntegration.enabled = $true
    Write-Host "Enabled WSL integration via 'wslIntegration'."
    $list = 'distros'
    # nested under wslIntegration
    if ($cfg.wslIntegration.distros -notcontains $DistroName) { $cfg.wslIntegration.distros += $DistroName }
    Write-Host "Added '$DistroName' to wslIntegration.distros."
    # Save and exit
    $cfg | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    goto RestartDocker
} else {
    Write-Warning "Unknown integration config in $configFile."; return
}

# Update distro list for earlier structures
if ($list -and $cfg.PSObject.Properties.Name -contains $list) {
    $arr = @($cfg.$list)
    if ($arr -notcontains $DistroName) { $arr += $DistroName; $cfg.$list = $arr; Write-Host "Added '$DistroName' to '$list'." }
    else { Write-Host "'$DistroName' already present in '$list'." }
} else {
    Write-Warning "Could not find list '$list' in $configFile."; return
}

# Save updated config
$cfg | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
Write-Host "Saved integration settings to $(Split-Path $configFile -Leaf)."

:RestartDocker
Write-Host "Restarting Docker Desktop..."
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ErrorAction SilentlyContinue
