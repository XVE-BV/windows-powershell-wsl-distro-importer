<#
.SYNOPSIS
  Enables the Windows ssh-agent and loads all private keys from a folder.
.DESCRIPTION
  - Starts and auto-configures the ssh-agent service.
  - Adds every file in the target directory that looks like a private key (i.e. not ending in .pub).
.PARAMETER KeyFolder
  The directory containing your SSH private keys. Defaults to "$HOME\.ssh".
.EXAMPLE
  # Use default folder:
  .\Add-AllSshKeys.ps1
.EXAMPLE
  # Specify a different folder:
  .\Add-AllSshKeys.ps1 -KeyFolder 'D:\Keys'
#>

[CmdletBinding()]
param(
    [string]$KeyFolder = "$env:USERPROFILE\.ssh"
)

# 1) Ensure ssh-agent is enabled & running
Write-Host "Enabling and starting ssh-agent service..."
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# 2) Find and add all private keys in the folder
if (-Not (Test-Path $KeyFolder)) {
    Write-Error "Key folder '$KeyFolder' does not exist."
    exit 1
}

Get-ChildItem -Path $KeyFolder -File |
        Where-Object { $_.Extension -ne '.pub' -and -not $_.Name.EndsWith('.pub') } |
        ForEach-Object {
            Write-Host "Adding SSH key:" $_.Name
            ssh-add $_.FullName
        }

Write-Host "✅ All keys from '$KeyFolder' have been added to the agent."
