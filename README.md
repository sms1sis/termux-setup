## **📱 Termux Unified Setup Script**

A single modular script to automate and customize your Termux environment — from base packages to Zsh + Starship, GitHub integration, and post‑setup tweaks.

---

## 🖥️ New Output Example
<p align="center">
  <img src="output_example.png" alt="Script Output" width="650">
</p>


---

## ✨ Features

- Enhanced User Interface
  - Color-coded log messages for better readability.
  - Progress spinners for long-running tasks.
  - Stylish banners for each setup section.

- Storage Setup
  - Requests access to shared storage on your device.

- Base Setup
  - Updates & upgrades Termux
  - Installs essential packages: git, curl, wget, zsh

- Shell & Prompt
  - Installs Zsh and the popular Oh My Zsh framework
  - Installs the blazing‑fast Starship prompt
  - Auto‑configures .zshrc with Starship, aliases, and an `upload` helper for Git
  - Installs `zsh-autosuggestions` and `zsh-syntax-highlighting`

- Font Setup
  - Downloads and installs the FiraCode Nerd Font for better icon support.

- Tools Setup
  - Installs useful utilities: `lsd`, `htop`, `tsu`, `unzip`, `micro`, `which`, and `openssh`.

- Post Setup
  - Interactive choice of Starship presets
  - Interactively configure command timeout and 12/24h time format
  - Backs up existing configs before overwriting

- Git & GitHub
  - Configure Git username & email
  - Generate a modern `ed25519` SSH key (if not already present)
  - Add key to SSH agent and tests the connection to GitHub

- Automation Friendly
  - Unified script with subcommands: `storage`, `base`, `tools`, `font`, `zsh`, `starship`, `post`, `git`, `all`
  - Safe shell switching (`--switch` for next login, `--switch-now` for immediate)

- Safety
  - Automatic backups of configs (.zshrc, starship.toml)
  - Logging to `termux_setup.log`

---

## 🚀 Quick Start

```bash
pkg update && pkg upgrade -y && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup.sh
```

---

## ⚡ Usage

- Full setup (recommended):
  ```bash
  ./setup.sh all --switch
  ```
  Runs all setup steps and sets Zsh as default for your next login.

- Individual components:
  ```bash
  ./setup.sh storage   # Grant storage access
  ./setup.sh base      # Install base packages
  ./setup.sh tools     # Install utilities
  ./setup.sh font      # Install Nerd Font
  ./setup.sh zsh       # Configure Oh My Zsh
  ./setup.sh starship  # Configure Starship prompt
  ./setup.sh post      # Interactive post-setup tweaks
  ./setup.sh git       # Configure Git and GitHub SSH
  ```

- Switch shell immediately (interactive only):
  ```bash
  ./setup.sh all --switch-now
  ```

---

## ⚙️ Optional Steps

- Customize Starship
  - Run `./setup.sh post` for interactive tweaks.
  - Edit manually at `~/.config/starship.toml`.
  - More themes: [Starship Presets](https://starship.rs/presets/)

- Check Logs
  - All actions are logged to `termux_setup.log`

---

## 🛠️ Troubleshooting

- If `chsh` is not available, the script falls back to adding `exec zsh` in `.bashrc`.
- If SSH key generation fails, check permissions on `~/.ssh` and rerun `./setup.sh git`.
- For Starship issues, run `starship doctor` to diagnose.

---

## 🙌 Credits

- Starship — minimal, blazing‑fast, infinitely customizable prompt  
- Termux — the Android terminal emulator that makes this possible  

---

## 💡 This script is modular. Run only what you need, or all for the full experience.
