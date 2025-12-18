## **📱 Termux Unified Setup Script**

A modular suite of scripts to automate and customize your development environment on Android. It supports both **Native Termux** and **Proot-Distro (Ubuntu/Debian)** environments.

The goal: Transform a fresh install into a powerful, visually appealing CLI workspace with minimal effort.

---

## 🖥️ Output Example
<p align="center">
  <img src="output_example.png" alt="Script Output" width="650">
</p>


---

## ✨ Features (Common)

- **Enhanced UI:** Color-coded logs, progress spinners, and stylish banners.
- **Shell & Prompt:** Installs **Zsh**, **Oh My Zsh**, and the **Starship** prompt.
- **Plugins:** Auto-installs `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- **Git Integration:** Auto-configures global user/email, generates `ed25519` SSH keys, and tests GitHub connectivity. Includes a custom `upload` alias for quick commits.
- **Config Management:** Automatically backs up existing files (`.zshrc`, `starship.toml`) before overwriting.

---

## 📦 Components

### 1. `setup.sh` (Native Termux)
Designed for the host Termux environment.
- **Storage:** Requests Android storage access.
- **Font:** Installs **FiraCode Nerd Font** for icon support.
- **Tools:** `lsd`, `htop`, `micro`, `openssh`, etc.

### 2. `proot-debian-setup.sh` (Ubuntu/Debian Proot)
An advanced adapter for Linux distributions running via `proot-distro`.
- **Sudo-Aware:** Automatically detects if running as **Root** or **User**. Uses `sudo` for system commands when needed.
- **Conflict Resolution:** Configures `.zshrc` to prioritize native container paths (`/usr/bin`) over Termux host paths, fixing "binary bleeding" issues.
- **Latest Starship:** Installs Starship via the official installer to `/usr/local/bin`, ensuring the latest version (avoiding stale apt packages).
- **Multi-User:** Can be used to set up the Root account *and* regular users.

---

## 🚀 Quick Start (Native Termux)

```bash
pkg update && pkg upgrade -y && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup.sh

# Run full setup
./setup.sh all --switch
```

---

## 🐧 Usage: Proot-Distro (Ubuntu/Debian)

For the best experience in a virtualized Linux environment, follow this two-step process:

### Step 1: System Setup (Run as Root)
First, log in as root to install core system tools (`sudo`, `zsh`, `git`, `curl`) and the global Starship binary.

```bash
# Login to your distro (e.g., ubuntu)
proot-distro login ubuntu

# Run the script inside the container
./proot-debian-setup.sh all
```
*Note: This ensures `sudo` is installed and permissions are correct.*

### Step 2: User Configuration (Run as Regular User)
If you use a regular user (e.g., `sms1sis`), log in as that user and run the script again. It will skip system installs and focus on your personal shell configuration.

```bash
# Login as your user
proot-distro login ubuntu --user <your_username>

# Run the script again
./proot-debian-setup.sh all --switch
```
*This configures your specific `.zshrc`, `oh-my-zsh`, and SSH keys.*

---

## ⚡ Setup Commands

| Command | Description |
| :--- | :--- |
| `./setup.sh all --switch` | Run full suite and switch shell on next login. |
| `./setup.sh base` | Install base packages only. |
| `./setup.sh tools` | Install developer utilities. |
| `./setup.sh zsh` | Configure Zsh + Oh My Zsh + Plugins. |
| `./setup.sh starship` | Configure Starship prompt & choose preset. |
| `./setup.sh git` | Setup Git user & generate SSH keys. |

---

## 🛠️ Troubleshooting

- **Proot Path Issues:** If `which starship` points to `/data/data/...`, the script's path fix hasn't applied. Ensure your `.zshrc` starts with `export PATH=/usr/local/bin:...`.
- **Permission Denied:** If setup fails in Proot, ensure you ran **Step 1** as root first to install `sudo`.

---

## 🙌 Credits

- [Starship](https://github.com/starship/starship) — minimal, blazing‑fast, infinitely customizable prompt  
- [Termux](https://github.com/termux/termux-app) — the Android terminal emulator that makes this possible