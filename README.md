**TL;DR**

1. Clone this repository locally.
2. Run `.\install.ps1` from an **Administrator** PowerShell prompt (type “i” + Tab to autocomplete).
3. Close all PowerShell, terminal, and File Explorer windows.
4. In Docker Desktop → **Settings** → **Resources** → **WSL Integration**, enable integration for your imported `XVEDistro`. 
5. Run `.\ssh.ps1` to load **all** your Windows SSH private keys into the agent for seamless Git access in WSL.

---

<a href="https://github.com/users/XVE-BV/projects/1">View Project Kanban Board</a>

---

# Windows 11 WSL2 Distro Importer (PowerShell)

Import a pre-built WSL2 distro into your Windows environment with a single PowerShell script. Ideal for spinning up a consistent PHP/Composer/Docker setup.

---

## What Is This?

**`install.ps1`** automates:

1. **Downloading** the latest (or specified) `xve-distro.tar` from GitHub Releases
2. **Importing** that tarball into WSL2 under a custom distro name
3. **Registering** it so you can launch your new Linux environment immediately

---

## Why Use It?

* **Consistency**: Everyone on the team runs the identical base.
* **Simplicity**: One script—no WSL commands to memorize.
* **Flexibility**: Import from GitHub or a local tarball.

---

## Prerequisites

* **Windows PowerShell** (run as Administrator)
* **WSL2** enabled on Windows 11
* **Docker Desktop** (for building locally)
* **Optional**: `GITHUB_TOKEN` env var (with **repo** scope) for private-repo access

---

## Usage

### Import the Latest Release from GitHub

```powershell
.\install.ps1
# (Optional) Specify name or location:
.\install.ps1 -DistroName XVE -InstallDir "$env:USERPROFILE\WSL\XVE"
```

### Import from a Local Tarball

```powershell
.\install.ps1 -Local -TarballPath ".\xve-distro.tar" -DistroName XVE
```

### Run the SSH-Key Loader

```powershell
# Load all keys from default folder
.\ssh.ps1

# Or specify another directory
.\ssh.ps1 -KeyFolder 'D:\other\.ssh'
```

---

## Available Parameters

| Parameter      | Type   | Default                    | Description                                                  |
| -------------- | ------ | -------------------------- | ------------------------------------------------------------ |
| `-DistroName`  | string | `XVE`                      | The WSL distro name to register.                             |
| `-InstallDir`  | string | `$env:USERPROFILE\WSL\XVE` | Windows folder where the distro filesystem will be created.  |
| `-Local`       | switch | (not set)                  | If present, import from `-TarballPath` instead of GitHub.    |
| `-TarballPath` | string | `.\xve-distro.tar`         | Path to the local tarball when using `-Local`.               |
| `-Token`       | switch | (not set)                  | Use `GITHUB_TOKEN` env var to authenticate GitHub API calls. |
| `-KeyFolder`   | string | `"$HOME\.ssh"`             | (ssh.ps1) Path to scan for private SSH key files. |

> **Shell Experience**: The importer sets your default login shell to **Zsh**, giving you a prettier prompt, auto-completion, and built-in aliases out of the box.

---

## Test your setup

1. Launch **XVEDistro** via WSL.
2. In the shell, run:

   ```sh
   git clone https://github.com/jonasvanderhaegen/laravel-boilerplate.git
   ```
3. Open your IDE at `~/apps/laravel-boilerplate` and start another XVE shell.
4. In that project folder, execute:

   ```sh
   ./scripts/sail.sh
   ```

   Accept any prompts and wait for setup to finish.
5. Run `sr` (alias for `sail composer run dev`).
6. Visit **[http://laravel.test](http://laravel.test)** in your browser.

---

## Docker WSL Integration

After import, enable Docker in your distro:

1. Open **Docker Desktop** → **Settings** → **Resources** → **WSL Integration**.
2. Toggle **XVEDistro** to “on.”
3. Click **Apply & Restart**.

---

## Troubleshooting

* **404 fetching releases**: Check the GitHub repo slug and ensure the release is **published**.
* **Auth failures**: Confirm `GITHUB_TOKEN` is set with `repo` scope.
* **WSL import errors**: Verify WSL2 is enabled (`wsl --list --online`) and you have write permission to `-InstallDir`.
* **Script needs Admin**: Always run PowerShell as Administrator.
* **SSH-key loader hangs**: Ensure you run it interactively to enter passphrases.

---


## New Helper: ssh.ps1

After import, you may want your existing Windows SSH keys available inside WSL. **ssh.ps1** will:

* **Enable & start** the Windows OpenSSH Agent
* **Scan** your `~\.ssh` folder (or a custom path) for **all private** keys
* **Add** each one to the agent so that your WSL distro can use them for Git operations

```powershell
.\ssh.ps1       # uses default $HOME\.ssh
.\ssh.ps1 -KeyFolder 'D:\MyKeys'
```

> **Warning:**
>
> * Passphrase-protected keys will prompt you for their passphrase interactively.
> * Make sure only your own account can read those private key files.
> * Running it in a non-interactive environment may hang if a key is locked.

---

## Uninstalling a Distro

```powershell
.\uninstall.ps1 -DistroName XVE
```

Stops all instances and removes the filesystem. Back up any important data first.

---

*Maintain a repeatable, zero-friction developer environment with a single install command.*
