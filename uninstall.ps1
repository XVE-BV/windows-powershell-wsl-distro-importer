<#
.SYNOPSIS
  Unregister (remove) a WSL2 distro by name and undo Docker Desktop WSL integration.
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

# --- Undo Docker Desktop WSL Integration ---
# Path to Docker Desktop settings
$settingsPath = Join-Path $Env:APPDATA "Docker\settings.json"

if (Test-Path $settingsPath) {
    $json = Get-Content $settingsPath -Raw | ConvertFrom-Json

    # Determine list key
    if ($json.PSObject.Properties.Name -contains 'wslDistros') {
        $listKey = 'wslDistros'
    } elseif ($json.PSObject.Properties.Name -contains 'enabledWSLDistros') {
        $listKey = 'enabledWSLDistros'
    } else {
        Write-Warning "Could not find WSL integration list in settings.json. Skipping removal."
        exit 0
    }

    # Remove the distro from the list
    $distros = @($json.$listKey) | Where-Object { $_ -ne $DistroName }
    $json.$listKey = $distros

    # Save updated settings
    $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "✅ Removed '$DistroName' from Docker Desktop WSL integration list."

    # Restart Docker Desktop to apply changes
    Write-Host "🔄 Restarting Docker Desktop..."
    Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
} else {
    Write-Warning "Docker Desktop settings.json not found. Cannot undo integration."
}
