<#
.SYNOPSIS
  Unregister (remove) a WSL2 distro by name and undo Docker Desktop WSL integration.
.DESCRIPTION
  Shuts down and unregisters the specified WSL distro, then removes it from Docker Desktop's WSL integration settings.
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
# Attempt to locate Docker Desktop settings
$roaming = Join-Path $Env:APPDATA 'Docker'
$paths = @(
    Join-Path $roaming 'settings.json',
    Join-Path $roaming 'settings-store.json'
)
$settingsPath = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $settingsPath) {
    Write-Warning "Docker Desktop settings not found at expected locations:`n  $($paths -join '`n  ')"
    return
}

# Load & parse settings
Try {
    $json = Get-Content $settingsPath -Raw | ConvertFrom-Json
} Catch {
    Write-Warning "Failed to parse JSON from $settingsPath: $_"
    return
}

# Determine list key for distros
if ($json.PSObject.Properties.Name -contains 'wslDistros') {
    $listKey = 'wslDistros'
} elseif ($json.PSObject.Properties.Name -contains 'enabledWSLDistros') {
    $listKey = 'enabledWSLDistros'
} else {
    Write-Warning "Could not find expected WSL-integration list key in $settingsPath"
    return
}

# Remove distro if present
$updated = @($json.$listKey) | Where-Object { $_ -ne $DistroName }
if (@($json.$listKey).Count -eq $updated.Count) {
    Write-Host "'$DistroName' was not in Docker Desktop WSL integration list."
} else {
    $json.$listKey = $updated
    # Save updated settings
    $json | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
    Write-Host "✅ Removed '$DistroName' from Docker Desktop WSL integration list in $([IO.Path]::GetFileName($settingsPath))."

    # Restart Docker Desktop to apply changes
    Write-Host "🔄 Restarting Docker Desktop..."
    Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ErrorAction SilentlyContinue
}
