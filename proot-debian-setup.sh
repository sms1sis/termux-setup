#!/bin/bash
# Debian Proot Unified Setup Script (Adapted from Termux version)

# --- Boilerplate and Utilities ---
set -uo pipefail
LOGFILE="$HOME/debian_setup.log"

# --- Privilege Handling ---
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "Warning: Running as non-root and 'sudo' is not installed."
        echo "Please run this script as root first to install sudo."
    fi
fi

# Source utilities
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    echo "Error: utils.sh not found."
    exit 1
fi

install_pkg() {
    local pkg=$1
    # Check if package is installed via dpkg (ignoring host PATH leakage)
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        execute "apt install -y $pkg" "Installing $pkg"
    else
        info "$pkg already installed, skipping."
    fi
}


# --- Main Setup Functions ---
main_banner() {
    clear
    echo -e "${C_RED}${C_BOLD}"
    cat << "EOF"
   ___      _     _               
  |   \ ___| |__ (_) __ _ _ _    
  | |) / -_) '_ \| |/ _` | ' \   
  |___/\___|_.__/|_|\__,_|_||_|  
      Proot Unified Setup
EOF
    echo -e "${C_RESET}"
}

# storage_setup removed (Termux-specific)

base_setup() {
    section "Base System Setup"
    execute "apt update -y && apt upgrade -y" "Updating and upgrading packages"
    for p in sudo git curl wget zsh; do install_pkg "$p"; done
    if command -v starship >/dev/null 2>&1; then
        info "Starship already installed."
    else
        execute "curl -sS https://starship.rs/install.sh | sh -s -- -y" "Installing latest Starship via official script"
    fi
    log "Base setup complete."
}

tools_setup() {
    section "Development Tools Installation"
    # Removed 'tsu' and 'which' (usually pre-installed or redundant in Debian)
    for p in lsd htop unzip micro; do install_pkg "$p"; done
    log "Utilities installed."
}

theme_setup() {
    section "Termux Color Theme Setup (Host)"
    TERMUX_HOME="/data/data/com.termux/files/home"
    CONF_DIR="$TERMUX_HOME/.termux"
    
    if [ ! -d "$TERMUX_HOME" ]; then
        warn "Termux home directory not found at $TERMUX_HOME. Theme installation might not work as expected."
        CONF_DIR="$HOME/.termux"
    fi

    mkdir -p "$CONF_DIR"

    # Theme Definitions
    declare -A THEMES
    
    THEMES["Default"]="# Default Termux
background=#000000
foreground=#FFFFFF
cursor=#FFFFFF"

    THEMES["Dracula"]="# Dracula
background=#282a36
foreground=#f8f8f2
cursor=#f8f8f2
color0=#21222c
color1=#ff5555
color2=#50fa7b
color3=#f1fa8c
color4=#bd93f9
color5=#ff79c6
color6=#8be9fd
color7=#f8f8f2
color8=#6272a4
color9=#ff6e6e
color10=#69ff94
color11=#ffffa5
color12=#d6acff
color13=#ff92df
color14=#a4ffff
color15=#ffffff"

    THEMES["One Dark"]="# One Dark
background=#282c34
foreground=#abb2bf
cursor=#abb2bf
color0=#282c34
color1=#e06c75
color2=#98c379
color3=#e5c07b
color4=#61afef
color5=#c678dd
color6=#56b6c2
color7=#abb2bf
color8=#5c6370
color9=#e06c75
color10=#98c379
color11=#e5c07b
color12=#61afef
color13=#c678dd
color14=#56b6c2
color15=#ffffff"

    THEMES["Gruvbox Dark"]="# Gruvbox Dark
background=#282828
foreground=#ebdbb2
cursor=#ebdbb2
color0=#282828
color1=#cc241d
color2=#98971a
color3=#d79921
color4=#458588
color5=#b16286
color6=#689d6a
color7=#a89984
color8=#928374
color9=#fb4934
color10=#b8bb26
color11=#fabd2f
color12=#83a598
color13=#d3869b
color14=#8ec07c
color15=#ebdbb2"

    THEMES["Solarized Light"]="# Solarized Light
background=#fdf6e3
foreground=#657b83
cursor=#657b83
color0=#073642
color1=#dc322f
color2=#859900
color3=#b58900
color4=#268bd2
color5=#d33682
color6=#2aa198
color7=#eee8d5
color8=#002b36
color9=#cb4b16
color10=#586e75
color11=#657b83
color12=#839496
color13=#6c71c4
color14=#93a1a1
color15=#fdf6e3"

    OPTIONS=("Default" "Dracula" "One Dark" "Gruvbox Dark" "Solarized Light")

    echo -e "${C_MAGENTA}${C_BOLD}🎨 Choose a Color Theme${C_RESET}"
    echo
    echo -e "  ${C_YELLOW}0)${C_RESET} ${C_RED}Back to Main Menu${C_RESET}"
    
    for i in "${!OPTIONS[@]}"; do
        idx=$((i+1))
        echo -e "  ${C_YELLOW}$idx)${C_RESET} ${C_BLUE}${OPTIONS[i]}${C_RESET}"
    done
    
    echo
    echo -n -e "${C_CYAN}Selection ${C_RESET}> "
    read -r choice
    echo

    if [ "$choice" == "0" ]; then
        return 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#OPTIONS[@]} )); then
        SELECTED="${OPTIONS[choice-1]}"
        echo "${THEMES[$SELECTED]}" > "$CONF_DIR/colors.properties"
        
        # Try to reload settings
        if command -v termux-reload-settings >/dev/null 2>&1; then
            termux-reload-settings
        elif [ -f "/data/data/com.termux/files/usr/bin/termux-reload-settings" ]; then
            /data/data/com.termux/files/usr/bin/termux-reload-settings
        else
            info "Theme applied. You may need to manualy reload Termux settings."
        fi
        
        log "Theme ${C_BOLD}$SELECTED${C_RESET} applied."
    else
        warn "Invalid selection."
    fi
}

gui_setup() {
    section "Desktop Environment (XFCE + VNC) Setup"
    execute "apt install -y xfce4 xfce4-goodies tigervnc-standalone-server" "Installing XFCE4 and TigerVNC"

    # VNC Start Script
    cat << 'EOF' > "/usr/local/bin/vnc-start"
#!/bin/bash
export DISPLAY=":1"
echo "Starting VNC Server on :1..."
if [ -f "$HOME/.vnc/pid" ]; then
    rm "$HOME/.vnc/pid"
fi
# Kill any existing on :1
vncserver -kill :1 >/dev/null 2>&1
rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

vncserver :1 -geometry 1280x720 -depth 24 -name "Debian" -xstartup "xfce4-session"
echo "VNC Started. Connect using address: localhost:5901"
EOF

    # VNC Stop Script
    cat << 'EOF' > "/usr/local/bin/vnc-stop"
#!/bin/bash
export DISPLAY=":1"
echo "Stopping VNC Server..."
vncserver -kill :1
rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1
echo "VNC Stopped."
EOF

    chmod +x "/usr/local/bin/vnc-start"
    chmod +x "/usr/local/bin/vnc-stop"
    
    log "GUI Setup Complete."
    info "Run ${C_BOLD}vnc-start${C_RESET} to start the desktop."
    info "Run ${C_BOLD}vnc-stop${C_RESET} to stop it."
    warn "You will need to set a VNC password on the first run."
}

backup_setup() {
    section "Backup & Restore (Proot Home)"
    echo -e "  ${C_YELLOW}1)${C_RESET} ${C_CYAN}Backup Home Directory${C_RESET}"
    echo -e "  ${C_YELLOW}2)${C_RESET} ${C_CYAN}Restore Home Directory${C_RESET}"
    echo -e "  ${C_YELLOW}0)${C_RESET} ${C_RED}Back${C_RESET}"
    echo -n -e "${C_CYAN}Choice > ${C_RESET}"
    read -r choice

    # Check for external storage access
    BACKUP_DIR="/sdcard"
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "/sdcard not found. Saving to $HOME/backups instead."
        BACKUP_DIR="$HOME/backups"
        mkdir -p "$BACKUP_DIR"
    fi

    case "$choice" in
        1)
            BACKUP_FILE="$BACKUP_DIR/debian_home_backup_$(date +%Y%m%d).tar.gz"
            info "Backing up $HOME to $BACKUP_FILE..."
            # Exclude cache and backups dir
            if tar -czf "$BACKUP_FILE" --exclude='.cache' --exclude='backups' -C "$HOME" . ; then
                log "Backup saved to $BACKUP_FILE"
            else
                error_exit "Backup failed."
            fi
            ;;
        2)
            echo -e "${C_CYAN}Enter full path to backup file:${C_RESET}"
            read -r restore_path
            if [ -f "$restore_path" ]; then
                warn "This will OVERWRITE files in $HOME. Continue? (y/n)"
                read -r confirm
                if [[ "$confirm" == "y" ]]; then
                    info "Restoring..."
                    if tar -xzf "$restore_path" -C "$HOME"; then
                        log "Restore complete."
                    else
                        error_exit "Restore failed."
                    fi
                else
                    info "Restore cancelled."
                fi
            else
                warn "File not found."
            fi
            ;;
        *) ;;
    esac
}

font_setup() {
    section "Font Installation (Termux Terminal)"
    # Target the Termux home directory's .termux folder
    TERMUX_HOME="/data/data/com.termux/files/home"
    FONT_DIR="$TERMUX_HOME/.termux"
    
    if [ ! -d "$TERMUX_HOME" ]; then
        warn "Termux home directory not found at $TERMUX_HOME. Font installation might not work as expected."
        FONT_DIR="$HOME/.termux"
    fi

    mkdir -p "$FONT_DIR"

    # Define font options (Name|URL)
    FONTS=(
        "FiraCode|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf"
        "JetBrainsMono|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf"
        "Meslo|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/M/Regular/MesloLGSNerdFont-Regular.ttf"
        "Hack|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/Regular/HackNerdFont-Regular.ttf"
        "SourceCodePro|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Regular/SauceCodeProNerdFont-Regular.ttf"
        "UbuntuMono|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/UbuntuMono/Regular/UbuntuMonoNerdFont-Regular.ttf"
        "CascadiaCode|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/CascadiaCode/Regular/CaskaydiaCoveNerdFont-Regular.ttf"
        "Agave|https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Agave/Regular/AgaveNerdFont-Regular.ttf"
    )

    DEFAULT_FONT="FiraCode"
    
    echo -e "${C_MAGENTA}${C_BOLD}🔡 Choose a Nerd Font for Termux${C_RESET}\n${C_CYAN}(press Enter for default: ${C_BOLD}$DEFAULT_FONT${C_RESET}${C_CYAN})${C_RESET}"
    echo
    echo -e "  ${C_YELLOW}0)${C_RESET} ${C_RED}Back to Main Menu${C_RESET}"
    for i in "${!FONTS[@]}"; do
        name=$(echo "${FONTS[i]}" | cut -d'|' -f1)
        idx=$((i+1))
        echo -e "  ${C_YELLOW}$idx)${C_RESET} ${C_BLUE}$name${C_RESET}"
    done
    echo
    echo -n -e "${C_CYAN}Selection ${C_RESET}> "
    read -r choice
    echo

    if [ "$choice" == "0" ]; then
        return 0
    fi

    SELECTED_URL=""
    SELECTED_NAME=""

    if [ -z "$choice" ]; then
        SELECTED_NAME="$DEFAULT_FONT"
        SELECTED_URL=$(echo "${FONTS[0]}" | cut -d'|' -f2)
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#FONTS[@]} )); then
        SELECTED_NAME=$(echo "${FONTS[choice-1]}" | cut -d'|' -f1)
        SELECTED_URL=$(echo "${FONTS[choice-1]}" | cut -d'|' -f2)
    else
        warn "Invalid selection, falling back to $DEFAULT_FONT"
        SELECTED_NAME="$DEFAULT_FONT"
        SELECTED_URL=$(echo "${FONTS[0]}" | cut -d'|' -f2)
    fi

    execute "curl -fLo $FONT_DIR/font.ttf $SELECTED_URL" "Installing $SELECTED_NAME Nerd Font to $FONT_DIR/font.ttf"
    
    # Try to reload settings if termux-reload-settings is accessible
    if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings
    elif [ -f "/data/data/com.termux/files/usr/bin/termux-reload-settings" ]; then
        /data/data/com.termux/files/usr/bin/termux-reload-settings
    else
        info "Font installed. You may need to manualy reload Termux settings or restart the app to see changes."
    fi
    
    log "Font $SELECTED_NAME installed."
}

zsh_setup() {
    section "Zsh & Oh My Zsh Configuration"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        export RUNZSH=no
        execute "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended" "Installing Oh My Zsh"
    else
        info "Oh My Zsh already installed."
    fi

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    info "Installing Zsh plugins..."
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        execute "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions" "Cloning zsh-autosuggestions"
    fi
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        execute "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" "Cloning zsh-syntax-highlighting"
    fi

    backup_file "$HOME/.zshrc"
    info "Creating new .zshrc configuration..."
    cat << 'EOF' > "$HOME/.zshrc"
    
# Seal Proot: Set only Ubuntu paths and remove Termux host paths
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set ZSH_THEME to something minimal or leave default.
# Starship will override the prompt, but OMZ needs a theme setting or defaults to robbyrussell.
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# --- Proot/Debian Specific Configuration ---

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- User Customizations ---

# Use lsd if available, otherwise fall back to ls --color
if command -v lsd >/dev/null 2>&1; then
    alias ls="lsd"
    alias ll="lsd -l"
    alias la="lsd -a"
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
fi

# Load Cargo (Rust) environment if it exists
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Load user aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Silence login message
touch ~/.hushlogin

# Initialize Starship
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# 🧠 Git quick upload helper for Zsh with colorful messages
upload() {
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  RED="\033[0;31m"
  CYAN="\033[0;36m"
  RESET="\033[0m"

  echo -e "\n${CYAN}📦 Starting Git upload...${RESET}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a Git repository!${RESET}\n"
    return 1
  fi

  git add .
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to stage files.${RESET}\n"
    return 1
  fi

  MSG="${1:-Update}"

  if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to commit.${RESET}\n"
  else
    if git commit -m "$MSG"; then
      echo -e "${GREEN}✅ Committed: ${MSG}${RESET}\n"
    else
      echo -e "${RED}❌ Commit failed.${RESET}\n"
      return 1
    fi
  fi

  if git remote | grep -q "^origin$"; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$BRANCH" = "HEAD" ]; then
      echo -e "${YELLOW}⚠️  Detached HEAD; cannot determine branch.${RESET}\n"
      return 1
    fi

    if git push origin "$BRANCH"; then
      echo -e "${GREEN}🚀 Pushed successfully to branch '${BRANCH}'!${RESET}\n"
    else
      echo -e "${RED}❌ Push failed.${RESET}\n"
    fi
  else
    echo -e "${YELLOW}⚠️  Remote 'origin' not found; push skipped.${RESET}\n"
  fi
}

EOF
    log "Zsh + plugins configured."
}

starship_setup() {
    section "Starship Prompt Configuration"
    mkdir -p "$HOME/.config"

    PRESETS=("catppuccin-powerline" "gruvbox-rainbow" "tokyo-night" "pastel-powerline")
    DEFAULT="catppuccin-powerline"

    echo
    echo -e "${C_MAGENTA}${C_BOLD}🎨 Choose a Starship preset${C_RESET}\n${C_CYAN}(press Enter for default: ${C_BOLD}$DEFAULT${C_RESET}${C_CYAN})${C_RESET}"
    echo
    echo -e "  ${C_YELLOW}0)${C_RESET} ${C_RED}Back to Main Menu${C_RESET}"
    for i in "${!PRESETS[@]}"; do
        idx=$((i+1))
        echo -e "  ${C_YELLOW}$idx)${C_RESET} ${C_BLUE}${PRESETS[i]}${C_RESET}"
    done
    echo
    echo -n -e "${C_CYAN}Selection ${C_RESET}> "
    read -r choice
    echo

    if [ "$choice" == "0" ]; then
        return 0
    fi

    if [ -z "$choice" ]; then
        CHOSEN="$DEFAULT"
    else
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if (( choice >= 1 && choice <= ${#PRESETS[@]} )); then
                CHOSEN="${PRESETS[choice-1]}"
            else
                warn "Invalid number, falling back to default: $DEFAULT"
                CHOSEN="$DEFAULT"
            fi
        else
            MATCH=""
            for p in "${PRESETS[@]}"; do
                if [[ "$p" == "$choice" || "$p" == "$choice"* ]]; then
                    MATCH="$p"
                    break
            fi
            done
            if [ -n "$MATCH" ]; then
                CHOSEN="$MATCH"
            else
                warn "Unrecognized preset name, falling back to default: $DEFAULT"
                CHOSEN="$DEFAULT"
            fi
        fi
    fi

    info "Selected preset: ${C_BOLD}$CHOSEN${C_RESET}"

    if command -v starship >/dev/null 2>&1 && starship preset "$CHOSEN" -o "$HOME/.config/starship.toml"; then
        log "Starship configured with ${C_BOLD}$CHOSEN${C_RESET} ${C_GREEN}✔${C_RESET}"
    else
        warn "Starship command not found or failed to apply preset $CHOSEN. Ensure Starship is installed."
    fi
}

post_setup() {
    section "Post-setup Starship Configuration"
    CFG="$HOME/.config/starship.toml"

    if [ ! -f "$CFG" ]; then
        warn "starship.toml not found at $CFG"
        return 1
    fi

    echo -e "\n${C_BOLD}${C_CYAN}🚀 Post-setup configuration for Starship prompt${C_RESET}\n"

    # Helper function to edit a key *only* if the section exists
    edit_key_in_section() {
        local section="$1"
        local key="$2"
        local value="$3"
        local section_header="\[$section\]" # Escaped for grep/sed
        local key_pattern="^\s*$key\s*="

        # 1. Check if section exists
        if ! grep -q "^$section_header" "$CFG"; then
            echo -e "  ${C_YELLOW}⚠️ Warning: Section [$section] not found. Skipping...${C_RESET}"
            return 1
        fi

        # 2. Section exists. Check if key exists within it.
        if sed -n "/^$section_header/,/^\[/{ /$key_pattern/p }" "$CFG" | grep -q .; then
            # Key exists, replace it
            sed -i "/^$section_header/,/^\[/{s/$key_pattern.*/$key = $value/}" "$CFG"
        else
            # Key doesn't exist, add it after the section header
            sed -i "/^$section_header/a $key = $value" "$CFG"
        fi
        return 0
    }

    # 1. Ask about command_timeout value
    read -rp "$(printf "${C_CYAN}❓ Enter command_timeout value (default 1000): ${C_RESET}")" cmd_timeout
    cmd_timeout="${cmd_timeout:-1000}"

    # Check if command_timeout already exists (as a global key)
    if grep -q "^command_timeout\s*=" "$CFG"; then
        # It exists, so replace it
        sed -i "s/^command_timeout\s*=.*/command_timeout = $cmd_timeout/" "$CFG"
    else
        # It doesn't exist, so add it as the first line
        sed -i "1i command_timeout = $cmd_timeout" "$CFG"
    fi
    echo -e "  ${C_GREEN}⏱ command_timeout set to $cmd_timeout.${C_RESET}"

    # 2. Ask about 12-hour time format
    read -rp "$(printf "${C_CYAN}❓ Do you want 12-hour AM/PM time format? (y/N): ${C_RESET}")" use_12h
    if [[ "$use_12h" =~ ^[Yy]$ ]]; then
        if edit_key_in_section "time" "time_format" "\"%I:%M %p\""; then
            edit_key_in_section "time" "disabled" "false"
            echo -e "  ${C_GREEN}✅ 12-hour time format applied.${C_RESET}"
        fi
    else
        if edit_key_in_section "time" "time_format" "\"%R\""; then
            edit_key_in_section "time" "disabled" "false"
            echo -e "  ${C_BLUE}⏰ 24-hour time format applied.${C_RESET}"
        fi
    fi

    # 3. Ask about two-liner prompt
    read -rp "$(printf "${C_CYAN}❓ Do you want a two-liner prompt? (y/N): ${C_RESET}")" two_liner
    if [[ "$two_liner" =~ ^[Yy]$ ]]; then
        if edit_key_in_section "line_break" "disabled" "false"; then
            echo -e "  ${C_GREEN}✅ Two-liner prompt enabled.${C_RESET}"
        fi
    else
        if edit_key_in_section "line_break" "disabled" "true"; then
            echo -e "  ${C_BLUE}➡ Two-liner prompt disabled.${C_RESET}"
        fi
    fi

    # 4. Ask about showing command duration
    read -rp "$(printf "${C_CYAN}❓ Do you want to show command duration? (y/N): ${C_RESET}")" show_duration
    if [[ "$show_duration" =~ ^[Yy]$ ]]; then
        if edit_key_in_section "cmd_duration" "disabled" "false"; then
            echo -e "  ${C_GREEN}✅ Command duration enabled.${C_RESET}"
        fi
    else
        if edit_key_in_section "cmd_duration" "disabled" "true"; then
            echo -e "  ${C_BLUE}➡ Command duration disabled.${C_RESET}"
        fi
    fi

    echo -e "\n${C_BOLD}${C_GREEN}🎉 Post-setup configuration complete!${C_RESET}\n"
    return 0
}

git_setup() {
    section "Git & SSH Configuration"

    info "${C_CYAN}Enter your Git credentials (or press Enter to keep existing):${C_RESET}"
    echo
    echo -n -e "- ${C_YELLOW}Username [$(git config --global user.name)]:${C_RESET} "
    read gitname
    echo -n -e "- ${C_YELLOW}Email [$(git config --global user.email)]:${C_RESET} "
    read gitemail

    if [ -n "$gitname" ]; then execute "git config --global user.name \"$gitname\"" "Setting Git Username"; fi
    if [ -n "$gitemail" ]; then execute "git config --global user.email \"$gitemail\"" "Setting Git Email"; fi
    log "${C_GREEN}Git global user configuration updated.${C_RESET}"

    SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        info "${C_YELLOW}No existing ed25519 SSH key found. Generating a new one.${C_RESET}"
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        # Ensure ssh-keygen is installed
        apt install -y openssh-client
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY_PATH" -N "" || error_exit "SSH Keygen failed."
    else
        info "${C_GREEN}Existing ed25519 SSH key found.${C_RESET}"
    fi

    info "${C_CYAN}Starting ssh-agent and adding key...${C_RESET}"
    echo
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH"

    info "${C_BOLD}Your public SSH key is:${C_RESET}"
    echo -e "${C_CYAN}"
    cat "$SSH_KEY_PATH.pub"
    echo -e "${C_RESET}"

    warn "${C_BOLD}Copy the key and add it to your GitHub account.${C_RESET}"
    read -p "Press [Enter] to test the connection..."
    echo
    info "${C_CYAN}Testing GitHub SSH connection...${C_RESET}"
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1)

    if [[ "$SSH_OUTPUT" == *"successfully authenticated"* ]]; then
        log "${C_GREEN}GitHub SSH connection is successful! ✔${C_RESET}"
    else
        warn "${C_RED}GitHub SSH connection failed. Manually verify your key.${C_RESET}"
    fi

    return 0
}

switch_shell() {
    section "Switching Default Shell"
    # Use the absolute path /usr/bin/zsh which is standard
    if $SUDO chsh -s /usr/bin/zsh "$USER"; then
        log "Default shell set to Zsh for $USER. Please run 'exit' and then log back in to apply."
    else
        error_exit "'chsh' command failed. You may not have necessary permissions, or /usr/bin/zsh is incorrect. Run 'which zsh' to confirm path."
    fi
}

dev_setup() {
    section "Developer Stack Setup (Debian)"
    echo -e "${C_YELLOW}Select stacks to install:${C_RESET}"
    echo -e "1) Python (python3, pip, venv, uv)"
    echo -e "2) Node.js (via fnm)"
    echo -e "3) Rust (via rustup)"
    echo -e "4) Neovim & Tmux"
    echo -e "5) All of the above"
    echo -e "0) Back"
    echo -n -e "${C_CYAN}Choice > ${C_RESET}"
    read -r choice
    
    case "$choice" in
        1) 
            install_pkg "python3"
            install_pkg "python3-pip"
            install_pkg "python3-venv"
            # Install uv via curl or pip. Pip is safer in proot if curl fails ssl? 
            # But we have pip.
            execute "pip3 install uv --break-system-packages" "Installing 'uv' (pip)" || execute "pip3 install uv" "Installing 'uv' (fallback)"
            ;;
        2) 
            info "Installing fnm..."
            execute "curl -fsSL https://fnm.vercel.app/install | bash" "Installing fnm"
            info "fnm installed. Please restart shell or source ~/.bashrc / ~/.zshrc."
            ;;
        3) 
            info "Installing Rust (rustup)..."
            execute "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "Installing rustup"
            ;;
        4) 
            install_pkg "neovim"
            install_pkg "tmux"
            ;;
        5)
            # Python
            install_pkg "python3"
            install_pkg "python3-pip"
            install_pkg "python3-venv"
            execute "pip3 install uv --break-system-packages" "Installing 'uv'" || execute "pip3 install uv" "Installing 'uv'"
            
            # Node
            execute "curl -fsSL https://fnm.vercel.app/install | bash" "Installing fnm"
            
            # Rust
            execute "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "Installing rustup"
            
            # Tools
            install_pkg "neovim"
            install_pkg "tmux"
            ;;
        0) return ;;
        *) warn "Invalid choice" ;;
    esac
}

# --- Dispatcher ---
run_all() {
    base_setup
    tools_setup
    font_setup
    zsh_setup
    starship_setup
    post_setup
    git_setup
}

interactive_menu() {
    # Intro animation
    clear
    main_banner
    typewriter "${C_CYAN}Welcome to the Debian Proot Setup Script!${C_RESET}" 0.02
    sleep 0.5

    while true; do
        clear
        main_banner
        
        MENU_ITEMS=(
            "${C_YELLOW}1)${C_RESET} ${C_CYAN}Full Setup (Run Everything)${C_RESET}"
            "${C_YELLOW}2)${C_RESET} ${C_CYAN}Base System Setup${C_RESET}"
            "${C_YELLOW}3)${C_RESET} ${C_CYAN}Install Development Tools${C_RESET}"
            "${C_YELLOW}4)${C_RESET} ${C_CYAN}Configure Terminal Theme${C_RESET}"
            "${C_YELLOW}5)${C_RESET} ${C_CYAN}Setup GUI (XFCE + VNC)${C_RESET}"
            "${C_YELLOW}6)${C_RESET} ${C_CYAN}Backup & Restore${C_RESET}"
            "${C_YELLOW}7)${C_RESET} ${C_CYAN}Install Nerd Fonts${C_RESET}"
            "${C_YELLOW}8)${C_RESET} ${C_CYAN}Configure Zsh & Oh My Zsh${C_RESET}"
            "${C_YELLOW}9)${C_RESET} ${C_CYAN}Configure Starship Prompt${C_RESET}"
            "${C_YELLOW}10)${C_RESET} ${C_CYAN}Configure Git & SSH Keys${C_RESET}"
            "${C_YELLOW}11)${C_RESET} ${C_GREEN}Switch Default Shell to Zsh${C_RESET}"
            "${C_YELLOW}12)${C_RESET} ${C_CYAN}Developer Stack Setup${C_RESET}"
            "${C_YELLOW}13)${C_RESET} ${C_CYAN}Check for Updates${C_RESET}"
            " "
            "${C_YELLOW}0)${C_RESET} ${C_RED}Exit${C_RESET}"
        )

        draw_box "Debian Proot Menu" "${MENU_ITEMS[@]}"

        echo
        echo -n -e "  ${C_BOLD}${C_YELLOW}Select an option [0-13]: ${C_RESET}"
        read -r menu_choice

        case "$menu_choice" in
            1) run_all ;;
            2) base_setup ;;
            3) tools_setup ;;
            4) theme_setup ;;
            5) gui_setup ;;
            6) backup_setup ;;
            7) font_setup ;;
            8) zsh_setup ;;
            9) starship_setup && post_setup ;;
            10) git_setup ;;
            11) switch_shell ;;
            12) dev_setup ;;
            13) self_update ;;
            0) echo -e "\n${C_GREEN}Goodbye!${C_RESET}"; exit 0 ;;
            *) warn "Invalid option, please try again."; sleep 1; continue ;;
        esac

        echo -e "\n${C_GREEN}Task completed. Press Enter to return to menu...${C_RESET}"
        read -r
    done
}

main() {
    if [ $# -eq 0 ]; then
        interactive_menu
        return
    fi

    main_banner
    # Track whether we should run switch_shell at the end
    RUN_SWITCH=0

    # Iterate all arguments in order
    for arg in "$@"; do
        case "$arg" in
            base) base_setup ;;
            tools) tools_setup ;;
            theme) theme_setup ;;
            gui) gui_setup ;;
            backup) backup_setup ;;
            font) font_setup ;;
            zsh) zsh_setup ;;
            starship) starship_setup ;;
            post) post_setup ;;
            git) git_setup ;;
            all) run_all ;;
            --switch)
                # Defer switch until after other requested work
                RUN_SWITCH=1
                ;;
            --switch-now)
                exec zsh
                ;;
            *)
                echo "Usage: $0 {base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"
                echo "Or run without arguments for interactive menu."
                return 1
                ;;
        esac
    done

    # If requested, attempt to switch shell now
    if [ "$RUN_SWITCH" -ne 0 ]; then
        switch_shell
    fi
}

main "$@"
