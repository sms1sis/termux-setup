# Termux Setup Script

This repository contains a comprehensive shell script to automate the setup of a complete development environment on a fresh installation of Termux on Android.

The script installs and configures Zsh, Oh My Zsh, Starship prompt, and a suite of useful development tools and plugins.

## Features

- **Shell & Prompt**:
  - Installs `Zsh` and sets it as the default shell.
  - Installs `Oh My Zsh` for Zsh configuration management.
  - Installs the beautiful and fast `Starship` cross-shell prompt.
  - Pre-configured with a modern, two-line theme.
- **Zsh Plugins**:
  - `zsh-autosuggestions` for fish-like command suggestions.
  - `zsh-syntax-highlighting` for real-time command highlighting.
- **Fonts**:
  - Automatically downloads and installs `FiraCode Nerd Font` to ensure all icons render correctly.
- **Utilities**:
  - `lsd`: A modern `ls` replacement with colors and icons.
  - `htop`: An interactive process viewer.
  - `tsu`: A sudo-like utility for gaining root privileges.
- **Automation & Helpers**:
  - Includes a `fix_starship_time.sh` script to easily switch Starship themes to 12-hour time.
  - Includes a custom `upload` function in `.zshrc` for quickly adding, committing, and pushing Git changes.

## Prerequisites

- A fresh installation of Termux.
- A working internet connection.

## How to Use

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/sms1sis/termux-setup.git
    cd termux-setup
    ```

2.  **Make the script executable:**

    ```bash
    chmod +x setup_my_termux.sh
    ```

3.  **Run the setup script:**

    ```bash
    ./setup_my_termux.sh
    ```

4.  **Set Zsh as the default shell:**

    After the script finishes, it will prompt you to run the following command manually. This is the final step.

    ```bash
    chsh -s zsh
    ```

5.  **Restart Termux:**

    Close and reopen the Termux application. Your new environment will be ready!

## Post-Installation

- **Configure Git:** The script creates a placeholder `~/.gitconfig` file. You must edit it with your name and email:

  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

- **Customize Starship:** You can change the prompt theme by editing the `~/.config/starship.toml` file. To try a new official preset, use the `starship preset` command and then fix the time format:

  ```bash
  # Example: Apply the 'gruvbox-rainbow' preset
  starship preset gruvbox-rainbow -o ~/.config/starship.toml
  
  # Fix the time format to 12-hour
  ./fix_starship_time.sh
  
  # Restart the shell to see changes
  exec zsh
  ```
