# XVE WSL Development Environment README

This README covers:

1. **Project Layout & Performance Tips**
2. **Persistent WSL Distro Usage**
3. **Patching & Updates**

---

## 1. Project Layout & Composer Performance Tips

To achieve near-native Composer speeds on Windows + WSL:

* **Keep your code on the Linux filesystem**
  Clone or move your repository into your WSL home (e.g. `~/projects/my-app`). Avoid mounting or working directly on `C:\…`, which suffers from high I/O latency.

* **Use Composer 2 & disable Xdebug for CLI**

  ```bash
  composer self-update --2
  # Ensure Xdebug is off when running installs/updates:
  php -dzend_extension=xdebug.so -r ""
  ```

* **Prefer dist packages & parallel downloads**

  ```bash
  composer config --global preferred-install dist
  composer config --global parallel-max 8
  ```

* **Leverage a persistent cache**
  By default, Composer stores cache under `~/.composer/cache`. Ensure this stays on the Linux filesystem so downloads and archives are reused across runs.

* **Exclude WSL files from Windows antivirus**
  Add your distro’s folder (`%USERPROFILE%\AppData\Local\Packages\…`) to Defender/AV exclusions to avoid on-access scanning overhead.

* **Run installs non-interactively & optimized**

  ```bash
  composer install --prefer-dist --optimize-autoloader --no-dev --no-progress --no-interaction
  ```

---

## 2. Persistent WSL Distro Usage

Treat your WSL distro as a long‑lived Linux environment:

1. **Import or install the distro once**

   ```powershell
   wsl --import XVE C:\WSL\XVE xve-distro.tar --version 2
   ```
2. **Clone projects inside WSL**

   ```bash
   cd ~
   mkdir -p projects && cd projects
   git clone git@github.com:your-org/your-app.git
   ```
3. **Global tooling & caches live in WSL**

    * Composer global packages (`composer global require …`) and caches remain intact
    * PHP extensions, certs, and scripts persist across sessions

Your teammates only need to import once; after that, they simply update code and use the existing distro.

---

## 3. Patching & Updating Your WSL Env

### A. OS‑level package updates

Run inside WSL whenever you need the latest security fixes or package versions:

```bash
sudo apk update
sudo apk upgrade
sudo apk cache clean
```

### B. Idempotent Bootstrap Script

Store a `bootstrap-wsl.sh` in your repo for one‑click environment refresh:

```bash
#!/bin/bash
set -e
# Update packages
echo "Updating Alpine packages..."
sudo apk update && sudo apk upgrade --available
# Install or upgrade tools
echo "Installing required packages..."
sudo apk add --no-cache php81-fpm php81-pecl-xdebug
# Copy configs
sudo cp configs/php-fpm.d/zz-socket.conf /usr/local/etc/php-fpm.d/
# Restart services
sudo pkill php-fpm || true
sudo php-fpm -D
echo "Reloading nginx..."
sudo nginx -s reload
```

Run with:

```bash
bash bootstrap-wsl.sh
```

### C. Full Distro Snapshot & Re‑Import

For major version bumps or to reset a drifting environment:

1. **Export on maintainer machine**:

   ```powershell
   wsl --export XVE xve-distro-YYYY-MM-DD.tar
   ```
2. **Share** the TAR with your team.
3. **Import** on developer machines:

   ```powershell
   wsl --unregister XVE
   wsl --import XVE C:\WSL\XVE xve-distro-YYYY-MM-DD.tar --version 2
   ```

This ensures everyone runs the same tested base environment.

---

With these practices in place, your team will enjoy consistent, fast Composer installs and a stable, maintainable WSL dev environment. Feel free to extend or customize this README to fit your workflow!
