# Why Run Your Applications Inside WSL?

While WSL2 makes it possible to interact with Windows filesystems, there are significant benefits to keeping your development projects and applications **inside** the WSL filesystem (e.g., under `\home`, `/var/www`, or a dedicated `applications` folder). Below are the key reasons and the drawbacks of running code on Windows-mounted drives (`/mnt/c/...`).

---

## 1. Superior File System Performance

* **Native ext4 vs. NTFS:** WSL2 uses a virtualized ext4 filesystem for your Linux distributions, which is optimized for typical Linux I/O patterns. Windows-mounted NTFS drives (`/mnt/c/`) suffer up to 10× slower file operations, especially for many small files (e.g., PHP frameworks, Node modules).
* **Faster builds and installs:** Composer, npm, and other package managers iterate over thousands of files. On NTFS, installs can take minutes longer, whereas inside WSL they complete in seconds.

---

## 2. Full System Call Compatibility

* **Linux-native behavior:** Many developer tools (Docker, inotify-based watchers, PHPMailer, etc.) rely on Linux-specific system calls. Inside WSL’s Linux kernel these calls work as expected; on `/mnt`, some calls are emulated or disabled, leading to unpredictable failures.
* **Consistent environment:** Running code inside WSL ensures parity with production Linux servers, reducing "it works on my machine" issues.

---

## 3. Reliable File Watching & Hot Reloading

* **inotify support:** File watchers (e.g., Laravel Mix, webpack, PHP’s `inotify`) trigger reliably only on WSL’s native FS. On `/mnt/c`, events may not fire, breaking live-reload, `npm run dev`, or unit test watchers.

---

## 4. Correct File Permissions & Symlinks

* **Unix permissions:** Linux file permissions (owner, group, execute bits) function only on the WSL filesystem. On NTFS, permissions are mapped and can cause permission denied errors, especially with deployment scripts or tools that rely on executable bits.
* **Symbolic links:** Many frameworks and libraries use symlinks. On Windows-mounted drives, symlinks can break or require elevated privileges, causing failures in autoloaders.

---

## 5. Network & DNS Integration

* **Local domains:** Tools like `mkcert` and per-project `.test` domains integrate seamlessly in WSL. On Windows mounts, binding ports and trusting certs can be more complex and error-prone.

---

## 6. Isolation & Clean State

* **Separate environments:** Keeping your code in WSL isolates it from accidental Windows-side interference (e.g., editors writing lock files, antivirus scans, or unwanted metadata).
* **Easier backups and snapshots:** You can export or snapshot your entire WSL distro without touching the Windows host filesystem.

---

### Conclusion

For the fastest, most reliable, and production‑aligned development experience, **always clone and run your projects inside the WSL filesystem**. Use the `applications` folder (or your preferred Linux path) rather than a Windows-mounted drive to fully leverage WSL’s performance and compatibility advantages.
