# windows 11 Powershell WSL2 Distro Importer

This project provides a PowerShell script (`Import.ps1`) to import a custom WSL2 distro either from the latest GitHub release or from a local tarball.

# What Is WSL2?

Windows Subsystem for Linux 2 (WSL2) lets you run a real Linux environment directly on Windows without the overhead of a full virtual machine. It provides:

- Native Linux kernel: Faster file system performance and full system call compatibility.

- Seamless integration: Access Windows files from Linux and vice versa, and use Linux tools alongside Windows apps.

- Lightweight: Lower resource usage compared to traditional VMs.

- This script automates importing a pre-built WSL2 distribution for your development environment.

# Features

- Multiple PHP versions: Choose per-project PHP via environment settings.
- Latest Composer version: Always have up-to-date dependency management.
- Nginx support: Generate per-project vhosts automatically using project-root configs.
- Secure local domains: Serve each project under its own .test domain.
- Latest Node.js & package managers: Access Node.js, npm, and Yarn globally.

> [!IMPORTANT]
> To leverage these features and enjoy optimized performance, your projects must reside inside the WSL filesystem under an applications folder. Running code from Windows-mounted drives (/mnt/…) is slower and may lead to reduced performance. <br>
> [Recommended to read more about it here](docs/why-run-inside-wsl.md)

# Import.ps1 Usage Guide

> [!TIP]
> Once the import finishes, please close this PowerShell window (and any open terminals or File Explorer windows) before checking your WSL distros otherwise the imported WSL won’t appear.

## Prerequisites

* **Windows PowerShell** (run as Administrator)
* **WSL2** enabled on Windows
* **`Import.ps1`** located in your project root
* **Optional**: A GitHub Personal Access Token (PAT) in `GITHUB_TOKEN` env var if your artifacts repo is private

---

## Script Features

* **Default behavior**: Downloads the **latest** `xve-distro.tar` from your GitHub artifacts repo and imports it.
* **Local import**: Use the `-Local` switch to skip GitHub and use a local tarball (`-TarballPath`).

## Parameters

| Parameter      | Type     | Default                    | Description                                                                     |
| -------------- | -------- | -------------------------- | ------------------------------------------------------------------------------- |
| `-DistroName`  | `string` | `XVE`                      | Name under which the distro will be registered in WSL.                          |
| `-InstallDir`  | `string` | `$env:USERPROFILE\WSL\XVE` | Windows folder where the distro filesystem will be created/imported.            |
| `-TarballPath` | `string` | `\.\xve-distro.tar`        | Path to local tarball when using `-Local`.                                      |
| `-Local`       | `switch` | N/A                        | When present, **skip** GitHub download and import directly from `-TarballPath`. |
| `-Token`       | `switch` | N/A                        | When present, it authorizes with your environment variable `GITHUB_TOKEN`  to access your private repository where the artifacts are released. |

## Environment Variables

* **`GITHUB_TOKEN`** (optional): A PAT with `repo` scope, required if your artifacts repo is **private**.

  ### Setting `GITHUB_TOKEN` in Windows PowerShell

  You can set your PAT as a user environment variable so it persists across sessions:

  ```powershell
  # Replace <YOUR_TOKEN> with your actual PAT
  [Environment]::SetEnvironmentVariable(
    'GITHUB_TOKEN',               # variable name
    '<YOUR_TOKEN>',               # PAT value
    'User'                        # scope: User, Machine, or Process
  )

  # Restart PowerShell or run this to load the new variable:
  $Env:GITHUB_TOKEN = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN','User')
  ```

## Examples

### 1. Import latest from GitHub (public repo)

```powershell
.\Import.ps1
```

### 2. Import latest from GitHub (private repo)

```powershell
# Set PAT in session
$Env:GITHUB_TOKEN = '<your_token_here>'

# Run import
.\Import.ps1
```

### 3. Import from local tarball

```powershell
.\Import.ps1 -Local
```

### 4. Import from custom local path

```powershell
.\Import.ps1 -Local -TarballPath '.\build\custom-xve.tar'
```

---

## Troubleshooting

* **404 when fetching releases**: Ensure:

  * The repo string (`owner/repo`) in the script matches exactly.
  * The GitHub release is **published** (not a draft).
  * For private repos, `GITHUB_TOKEN` is set and has `repo` scope.

* **Permission errors**: Verify you’re running PowerShell **as Administrator**.

* **WSL import issues**: Make sure WSL2 is enabled and you have sufficient disk space in the target `InstallDir`.

---

For further assistance, please reach out to the dev team or open an issue in the artifacts repository.

---

## FAQ

**Q:** If the repository is public, can other people upload releases to it without a GitHub token?
**A:** No. Even for public repositories, uploading a release or attaching assets via the GitHub API requires authentication. Users must have a Personal Access Token (PAT) with the appropriate `repo` scope (or be granted write access via a team membership) and must set `GITHUB_TOKEN` in their environment before running the script.



# Uninstall (Remove.ps1)

Remove.ps1 is a helper script to completely remove your WSL2 distro. When executed, it:

1. Ensures PowerShell is running as Administrator.
2. Confirms the specified distro name exists.
3. Prompts you to confirm the deletion to avoid mistakes.
4. Stops all WSL instances and unregisters the distro, cleaning up its files.
5. Displays a final message once removal is complete.

Usage:

```powershell
.\Remove.ps1 [-DistroName YourDistroName]
```
If you omit -DistroName, it defaults to XVE. Always back up any important data before running removal.
