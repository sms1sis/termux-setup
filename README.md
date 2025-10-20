# 📲 Termux Setup Script

*A comprehensive shell script to automate the setup of a complete development environment on a fresh Termux installation.*

## 🖥️ Output Example
<p align="center">
  <img src="output_example.png" alt="Script Output" width="650">
</p>

---

## ✨ Features

- **Shell & Prompt**:
  - Installs `Zsh` and `Oh My Zsh`.
  - Installs the `Starship` cross-shell prompt, pre-configured with the `catppuccin-powerline` preset.
- **Zsh Plugins**:
  - `zsh-autosuggestions` for fish-like command suggestions.
  - `zsh-syntax-highlighting` for real-time command highlighting.
- **Fonts**:
  - Automatically downloads and installs `FiraCode Nerd Font`.
- **Utilities**:
  - `lsd`: A modern `ls` replacement.
  - `htop`: An interactive process viewer.
  - `tsu`: A sudo-like utility.
- **Automation**:
  - Includes `post_setup.sh`  This is to configure starship.toml
  - Includes  `setup_git_github.sh.sh` This is to configuring user Git identity and setting up an SSH key to connect to       GitHub.

---

## 🚀 How to Use

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/sms1sis/termux-setup.git
    cd termux-setup
    ```

2.  **Make the scripts executable:**
    ```bash
    chmod +x setup_my_termux.sh setup_git_github.sh post_setup.sh
    ```

3.  **Run the main setup script:**
    ```bash
    ./setup_my_termux.sh
    ```
4. **Customize starship.toml**
   ```bash
   ./post_setup.sh
   ```

 # ⚡ On fresh termux run
```bash
pkg update && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup_my_termux.sh setup_git_github.sh post_setup.sh
./setup_my_termux.sh
./post_setup.sh
```
---

## ⚙️ Optional Steps

### 1. Configure Git and GitHub

After the main setup, run the dedicated Git setup script. This will guide you through configuring your Git identity and setting up an SSH key to connect to GitHub.

```bash
./setup_git_github.sh
```

### 2. Customize Starship

The `catppuccin-powerline` preset is installed by default. You can customize it by editing `~/.config/starship.toml`.
To find more themes, visit the [Starship Presets website](https://starship.rs/presets/).

To apply a new preset:
```bash
# Example: Apply the 'tokyo-night' preset
starship preset tokyo-night -o ~/.config/starship.toml
```
---

## 🙌 Credit
- [starship](https://github.com/starship/starship): Fow making the minimal, blazing-fast, and infinitely customizable prompt for any shell!
