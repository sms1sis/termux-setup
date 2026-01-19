## **📱 Termux Unified Setup Script**

A modular suite of scripts to automate and customize your development environment on Android. It supports both **Native Termux** and **Proot-Distro (Ubuntu/Debian)** environments.

The goal: Transform a fresh install into a powerful, visually appealing CLI workspace with minimal effort.

---

## 🖥️ Output Example
<p align="center">
  <img src="output_example.png" alt="Script Output" width="650">
</p>


---

## ✨ Features

- **Interactive Menu:** Run without arguments to access a stylish selection menu.
- **Enhanced UI:** Color-coded logs, progress spinners, and stylish banners.
- **Modular Architecture:** Core logic separated into `utils.sh` for stability and easy maintenance.
- **Self-Update:** Built-in ability to check for and pull the latest script updates from GitHub.
- **Shell & Prompt:** Installs **Zsh**, **Oh My Zsh**, and the **Starship** prompt.
- **Font Selection:** Choose from multiple **Nerd Fonts** (FiraCode, JetBrainsMono, Meslo, etc.) to enable icon support.
- **Terminal Themes:** Apply color schemes like Dracula, One Dark, Gruvbox, etc.
- **Termux API:** Seamless integration with Android API (Battery, SMS, Clipboard).
- **Desktop Environment:** One-click setup for XFCE4 + TigerVNC (GUI).
- **Backup & Restore:** Easy backup/restore utility for your home directory.
- **Termux Services:** Integration with runit for managing background services.
- **Developer Stacks:** Dedicated menu to install full tech stacks:
    - **Python:** Python + `pip` + `uv` (ultra-fast package installer).
    - **Node.js:** `fnm` (Fast Node Manager) for managing Node versions.
    - **Rust:** `rustup` (Debian) or `pkg` (Termux).
    - **Tools:** Neovim & Tmux.
- **Plugins:** Auto-installs `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- **Git Integration:** Auto-configures global user/email, generates `ed25519` SSH keys, and tests GitHub connectivity. Includes a custom `upload` alias for quick commits.
- **Config Management:** Automatically backs up existing files (`.zshrc`, `starship.toml`) before overwriting.

---

## 📦 Components

### 1. `setup.sh` (Native Termux)
Designed for the host Termux environment.
- **Interactive Menu:** Easily toggle specific setup tasks.
- **Storage:** Requests Android storage access.
- **Dev Stacks:** Install Python, Node, Rust, Neovim, etc., with a single click.
- **Font Selection:** Menu-driven installation of popular Nerd Fonts.
- **Tools:** `lsd`, `htop`, `micro`, `openssh`, etc.

### 2. `proot-debian-setup.sh` (Ubuntu/Debian Proot)
An advanced adapter for Linux distributions running via `proot-distro`.
- **Unified Interface:** Shares the same look and feel as the native script.
- **Sudo-Aware:** Automatically detects if running as **Root** or **User**. Uses `sudo` for system commands when needed.
- **Dev Stacks (Proot):** Installs Linux-native versions of tools (e.g., `rustup` script instead of Termux pkg).
- **Conflict Resolution:** Configures `.zshrc` to prioritize native container paths (`/usr/bin`) over Termux host paths, fixing "binary bleeding" issues.
- **Font Setup:** Cross-environment font installer that updates your *Termux* terminal settings from *within* PRoot.

---

## 🚀 Quick Start (Native Termux)

```bash
pkg update && pkg upgrade -y && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup.sh

# Start the interactive setup
./setup.sh
```

---

## 🐧 Usage: Proot-Distro (Ubuntu/Debian)

The script is **Sudo-Aware**. If you are running as a regular user with sudo privileges, it will automatically handle system-level installations while keeping your personal configuration in your home directory.

### **Direct Setup (Recommended)**
Log in as your preferred user and run the script. It will prompt for your sudo password when installing system tools.

```bash
# Login as your user (e.g., sms1sis)
proot-distro login ubuntu --user <your_username>

# Clone repo if not already done inside proot
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x proot-debian-setup.sh

# Run the interactive setup
./proot-debian-setup.sh
```

---

## ⚡ Setup Commands

The scripts can be run with arguments for automation or without arguments for the interactive menu.

| Command | Description |
| :--- | :--- |
| `./setup.sh` | **Open the Interactive Menu (Recommended)** |
| `./setup.sh all --switch` | Run full suite and switch shell on next login. |
| `./setup.sh base` | Install base packages only. |
| `./setup.sh tools` | Install developer utilities. |
| `./setup.sh theme` | Open Color Theme selection menu. |
| `./setup.sh api` | Install Termux API & Aliases. |
| `./setup.sh gui` | Install XFCE4 Desktop & VNC. |
| `./setup.sh services` | Install Termux Services (runit). |
| `./setup.sh backup` | Run Backup & Restore utility. |
| `./setup.sh font` | Open Font selection menu. |
| `./setup.sh zsh` | Configure Zsh + Oh My Zsh + Plugins. |
| `./setup.sh starship` | Configure Starship prompt & choose preset. |
| `./setup.sh git` | Setup Git user & generate SSH keys. |
| **New Features** | |
| Select in Menu | **Developer Stack Setup** (Python, Node, Rust, etc.) |
| Select in Menu | **Check for Updates** (Self-update script) |

---

## 🛠️ Troubleshooting

- **Proot Path Issues:** If `which starship` points to `/data/data/...`, the script's path fix hasn't applied. Ensure your `.zshrc` starts with `export PATH=/usr/local/bin:...`.
- **Permission Denied:** If setup fails in Proot, ensure you ran **Step 1** as root first to install `sudo`.

---

## 🙌 Credits

- [Starship](https://github.com/starship/starship) — minimal, blazing‑fast, infinitely customizable prompt  
- [Termux](https://github.com/termux/termux-app) — the Android terminal emulator that makes this possible