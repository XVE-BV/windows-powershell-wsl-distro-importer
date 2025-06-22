**TLDR:**

1. Clone this repository locally.
2. Run `.\install.ps1` from an **Administrator** PowerShell prompt. (write "i" and press tab for autocompletion)
3. Close all PowerShell, terminal, and File Explorer windows.
4. In Docker Desktop → Settings → Resources → WSL Integration, enable integration for your imported `XVEDistro`.

**Test your setup:**

* Launch the `XVEDistro` distro via WSL.
* Inside the distro shell, run:

  ```sh
  git clone https://github.com/jonasvanderhaegen/laravel-boilerplate.git
  ```
* Open your IDE on `~/apps/laravel-boilerplate` and start another XVE shell.
* In the project folder, execute:

  ```sh
  ./scripts/sail.sh
  ```

  Accept prompts and wait for setup to complete.
* Run `sr` (alias for `sail composer run dev`).
* Visit `http://laravel.test` in your browser.

---

<a href="https://github.com/users/jonasvanderhaegen-xve/projects/1">View Project Kanban Board</a>

---

# Windows 11 WSL2 Distro Importer (PowerShell)

Import a pre-built WSL2 distro into your Windows environment with a single PowerShell script. Ideal for bringing up a consistent development setup with zero manual configuration.

## What Is This?

`install.ps1` automates:

1. **Downloading** the latest or specified `xve-distro.tar` from GitHub Releases (public or private).
2. **Importing** that tarball into WSL2 under a custom distro name.
3. **Registering** it so you can launch your new Linux environment immediately.

## Why Use It?

* **Consistency**: Everyone on the team runs the identical base distro.
* **Simplicity**: One script, no manual WSL commands to remember.
* **Flexibility**: Import from GitHub or use a local tarball.

---

## Prerequisites

* **Windows PowerShell** (start as Administrator)
* **WSL2** enabled on Windows 11
* **Docker Desktop** (to build the distro, if generating locally)
* **Optional**: `GITHUB_TOKEN` env var with `repo` scope for private repo access

---

## Usage

### Import the Latest Release from GitHub

```powershell
# In the folder containing install.ps1:

#This is enough really. type "i", then press tab and enter.
.\install.ps1

# (optional) For other distro
.\install.ps1 -DistroName XVE -InstallDir "$env:USERPROFILE\WSL\XVE"
```

* Downloads the most recent `xve-distro.tar` published on your GitHub artifacts repo.
* Imports as WSL distro named `XVE` at `C:\Users\You\WSL\XVE`.

### Import from a Local Tarball

```powershell
.\install.ps1 -Local -TarballPath ".\xve-distro.tar" -DistroName XVE
```

* Skips GitHub download and uses the specified local tarball.

### Available Parameters

> **Shell Experience**: The importer configures the default login shell as **Zsh**, providing a richer prompt, auto-completion, and the preconfigured aliases out of the box.

### Available Parameters

| Parameter      | Type   | Default                    | Description                                                  |
| -------------- | ------ | -------------------------- | ------------------------------------------------------------ |
| `-DistroName`  | string | `XVE`                      | The WSL distro name to register.                             |
| `-InstallDir`  | string | `$env:USERPROFILE\WSL\XVE` | Filesystem path for the imported distro.                     |
| `-Local`       | switch | (not set)                  | If present, import from `-TarballPath` instead of GitHub.    |
| `-TarballPath` | string | `.\xve-distro.tar`         | Path to the local tarball when using `-Local`.               |
| `-Token`       | switch | (not set)                  | Use `GITHUB_TOKEN` env var to authenticate GitHub API calls. |

---

## How It Works

1. **Fetch**: If `-Local` is not used, the script calls GitHub API to locate the latest release and downloads its tarball.
2. **WSL Import**: Runs `wsl --import` to register a new WSL2 distro with the tarball contents.
3. **Clean Up**: Removes any temporary files and confirms the new distro is available via `wsl -l -v`.

---

## Preconfigured Shell Aliases

When you launch the imported distro, several helpful aliases and functions are already available in your Zsh environment via `~/.zshrc`. These include:

* `sail()` – A wrapper function for Laravel Sail:

  ```sh
  sail() {
    if [[ -f vendor/bin/sail ]]; then
      zsh vendor/bin/sail "$@"
    else
      echo "vendor/bin/sail not found"
    fi
  }
  ```

  Use it to run Sail without typing `vendor/bin/sail`.

* `s`  – Short alias for `sail ` (appends a space):

  ```sh
  alias s='sail '
  ```

  So you can do:

  ```sh
  s up -d        # equivalent to sail up -d
  s down         # equivalent to sail down
  ```

* `sa` – Shortcut for `sail artisan `:

  ```sh
  alias sa='sail artisan '
  ```

  Run Artisan commands quickly:

  ```sh
  sa migrate     # runs php artisan migrate
  sa tinker      # runs php artisan tinker
  ```

* `sc` – Shortcut for `sail composer `:

  ```sh
  alias sc='sail composer '
  ```

  Manage Composer dependencies inside Sail:

  ```sh
  sc install     # runs composer install
  sc update      # runs composer update
  ```

* Database migration shortcuts:

  ```sh
  alias sm='sa migrate'
  alias smf='sa migrate:fresh'
  alias smfs='sa migrate:fresh --seed'
  ```

  Quickly migrate or refresh+seed your database.

---

## Docker WSL Integration

After importing your new WSL distro, Docker Desktop does not automatically allow it to access the Docker daemon. To enable Docker CLI commands inside your distro, follow these steps:

1. Open **Docker Desktop** on Windows.
2. Go to **Settings** (gear icon) → **Resources** → **WSL Integration**.
3. Find your imported distro (e.g. `XVEDistro`) in the list and **toggle its switch to “on”**.
4. Click **Apply & Restart**.

This step mounts the Docker Desktop daemon’s socket (`/var/run/docker.sock`) into your WSL2 distro, so commands like `docker ps`, `docker compose up`, and Laravel Sail will work seamlessly without installing a separate Docker Engine inside WSL.

---

## Troubleshooting

* **404 Errors Fetching Releases**: Verify the GitHub repo slug in the script matches your artifacts repo and that the latest release is published (not draft).
* **Authentication Failures**: Ensure `GITHUB_TOKEN` is set and has `repo` scope for private repos.
* **WSL Import Fails**: Confirm WSL2 feature is enabled (`wsl --list --online`) and you have write access to `-InstallDir`.
* **Script Requires Admin**: Always run PowerShell as Administrator, or `wsl --shutdown` may fail.

---

## Uninstalling a Distro

Use the companion `uninstall.ps1` script to unregister and clean up a WSL2 distro:

```powershell
.\uninstall.ps1 -DistroName XVE
```

This will stop all WSL instances for that distro and remove its filesystem.

---

*Maintain a consistent developer experience with a single import command.*
