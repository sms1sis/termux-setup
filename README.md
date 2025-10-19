# 📲 Termux Setup Script

*A comprehensive shell script to automate the setup of a complete development environment on a fresh Termux installation.*

---

## ✨ Features

- **Shell & Prompt**:
  - Installs `Zsh` and `Oh My Zsh`.
  - Installs the `Starship` cross-shell prompt, pre-configured with the `gruvbox-rainbow` preset.
- **Zsh Plugins**:
  - `zsh-autosuggestions` for fish-like command suggestions.
  - `zsh-syntax-highlighting` for real-time command highlighting.
- **Fonts**:
  - Automatically downloads and installs `FiraCode Nerd Font`.
- **Utilities**:
  - `lsd`: A modern `ls` replacement.
  - `htop`: An interactive process viewer.
  - `tsu`: A sudo-like utility.
- **Automation & Helpers**:
  - Includes a `setup_git_github.sh` script to interactively configure your Git identity and connect to GitHub via SSH.
  - Includes a `fix_starship_time.sh` script to easily switch Starship themes to 12-hour time.
  - Includes a custom `upload` function in `.zshrc` for quickly pushing Git changes.

---

## 🚀 How to Use

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/sms1sis/termux-setup.git
    cd termux-setup
    ```

2.  **Make the scripts executable:**
    ```bash
    chmod +x setup_my_termux.sh setup_git_github.sh
    ```

3.  **Run the main setup script:**
    ```bash
    ./setup_my_termux.sh
    ```

4.  **Set Zsh as the default shell:**
    After the script finishes, run the following command manually:
    ```bash
    chsh -s zsh
    ```

5.  **Restart Termux:**
    Close and reopen the Termux application to apply all changes.

## ⚡ On clean termux run

```bash
pkg update && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup_my_termux.sh setup_git_github.sh
./setup_my_termux.sh
chsh -s zsh
```
---

## ⚙️ Next Steps

### 1. Configure Git and GitHub

After the main setup, run the dedicated Git setup script. This will guide you through configuring your Git identity and setting up an SSH key to connect to GitHub.

```bash
./setup_git_github.sh
```

### 2. Customize Starship

The `gruvbox-rainbow` preset is installed by default. You can customize it by editing `~/.config/starship.toml`. To find more themes, visit the [Starship Presets website](https://starship.rs/presets/).

To apply a new preset:
```bash
# Example: Apply the 'pastel-powerline' preset
starship preset pastel-powerline -o ~/.config/starship.toml

# Fix the time format to 12-hour (optional)
./fix_starship_time.sh

# Restart the shell to see changes
exec zsh
```
