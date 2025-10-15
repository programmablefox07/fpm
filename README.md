# FPM — FreeBSD Package Manager (apt-style Wrapper)

FPM is a command-line package manager for FreeBSD and BSD-based desktops like NomadBSD or GhostBSD.
It provides an apt-like interface, translating familiar commands into FreeBSD’s native `pkg` operations.

Think of it as:

apt → dpkg
fpm → pkg

---

## Features

- Familiar `apt`-style syntax for FreeBSD users.
- Supports `install`, `remove`, `update`, `upgrade`, `find`, `id`, `list`, `autoremove`, and `history`.
- Optional colored output for readability.
- Auto-confirm (`-y`) for non-interactive installs.
- Easy aliasing for Debian/Ubuntu users switching to FreeBSD.
- Extensible for ports support, logging, or progress bars.

---

## Command Structure

| FPM Command     | Description                          | pkg Equivalent       |
|-----------------|--------------------------------------|--------------------|
| `fpm update`    | Update repository catalog            | `pkg update`        |
| `fpm upgrade`   | Upgrade all installed packages       | `pkg upgrade`       |
| `fpm install <package>` | Install a package              | `pkg install <package>` |
| `fpm remove <package>`  | Remove a package               | `pkg delete <package>` |
| `fpm find <package>`    | Search for a package           | `pkg search <package>` |
| `fpm id <package>`      | Show package information       | `pkg info <package>` |
| `fpm list`      | List all installed packages          | `pkg info`          |
| `fpm autoremove`| Remove orphaned dependencies         | `pkg autoremove`    |
| `fpm history`   | Show install/update/remove history   | Optional: custom log|

### Flags
- `-y` → Auto-confirm prompts (like `apt -y`)
- `-v` → Verbose output

---

## Example Usage

```bash
# Update repositories
fpm update

# Install Firefox
fpm install firefox

# Remove Vim
fpm remove vim

# Upgrade all installed packages
fpm upgrade

# Search for a package
fpm find nano

# Show info about a package
fpm id firefox
