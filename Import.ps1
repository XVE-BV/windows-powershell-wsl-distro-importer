
    
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
    
    # Quick Test: verify GitHub release endpoint
    # To test in PowerShell prompt, run:
    # ```powershell
    # $repo = 'jonasvanderhaegen/xve-artifacts'
    # Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" \
    #     -Headers @{ 'User-Agent'='XVE-Importer'; Authorization="token <YOUR_GITHUB_TOKEN>" } \
    #     -UseBasicParsing
    # ```
    # If that returns JSON, the repo path and token are correct.
    
    # Determine script folder
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Push-Location $scriptDir
    
    if (-not $Local) {
            # Download latest release from GitHub (requires a PAT if private)
        $repo      = 'jonasvanderhaegen-xve/xve-artifacts'  # correct owner/repo with -xve suffix
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
