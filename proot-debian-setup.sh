#!/bin/bash
# Debian Proot Unified Setup Script
# by sms1sis

VERSION="1.2.0"
set -uo pipefail
LOGFILE="$HOME/debian_setup.log"

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "Warning: Running as non-root and 'sudo' is not installed."
    fi
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
    source "$SCRIPT_DIR/utils.sh"
else
    echo "Error: utils.sh not found."
    exit 1
fi

install_pkg() {
    local pkg=$1
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        execute "apt-get install -y $pkg" "Installing $pkg"
    else
        info "$pkg already installed, skipping."
    fi
}


# --- Main Setup Functions ---
main_banner() {
    clear
    echo -e "\033[1;36m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃         ★  Debian  Proot  Setup  Tool  ★        ┃"
    echo -e "┃                   by  sms1sis                   ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

    sleep 0.4

    echo -e "\033[1;32m"
    echo "    ██████╗ ███████╗██████╗  ██████╗  ██████╗ ████████╗"
    echo "    ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝"
    echo "    ██║  ██║█████╗  ██████╔╝██║   ██║██║   ██║   ██║   "
    echo "    ██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║   ██║   "
    echo "    ██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝   ██║   "
    echo "    ╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   "
    echo "           Debian Proot Unified Setup Script"
    echo -e "\033[0m"

    sleep 1.5

    echo -e "\033[1;33m* ♻️  Initializing environment...\033[0m"
    sleep 0.3
    echo -e "\033[1;33m* 🔍 Checking Proot environment...\033[0m"
    sleep 0.3
    echo -e "\033[1;33m* 🔧 Loading configuration...\033[0m"
    sleep 0.3
    echo -e "\033[1;33m* ⏳ Preparing UI Engine...\033[0m"
    sleep 0.3

    echo -e "\n\033[1;36mLoading sms1sis Presents...\033[0m"
    echo -e "\033[1;36m*Debian Proot Setup*....\033[0m\n"

    for i in 10 25 40 55 70 85 100; do
        bars=$((i/5))
        printf "["
        for ((j=0; j<bars; j++)); do printf "█"; done
        for ((j=bars; j<20; j++)); do printf " "; done
        printf "] ${i}%%\r"
        sleep 0.12
    done
    echo

    sleep 0.4

    echo -e "\033[1;36m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  Developed By : sms1sis                         ┃"
    echo -e "┃  GitHub       : github.com/sms1sis              ┃"
    printf "┃  Version      : v%-31s┃\n" "$VERSION"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

    sleep 1.5
}

base_setup() {
    section "Base System Setup"
    local apt_opts='-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"'
    check_internet
    execute "apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y $apt_opts" "Updating and upgrading packages"
    for p in sudo git curl wget zsh procps; do install_pkg "$p"; done
    if [ -f "/usr/local/bin/starship" ] || [ -f "/usr/bin/starship" ]; then
        info "Starship already installed."
    else
        execute "curl -sS https://starship.rs/install.sh | sh -s -- -y" "Installing latest Starship"
    fi
    log "Base setup complete."
}

tools_setup() {
    section "Development Tools Installation"
    for p in lsd htop unzip micro; do install_pkg "$p"; done
    log "Utilities installed."
}

theme_setup() {
    section "Termux Color Theme Setup (Host)"
    TERMUX_HOME="/data/data/com.termux/files/home"
    CONF_DIR="$TERMUX_HOME/.termux"
    if [ ! -d "$TERMUX_HOME" ]; then
        warn "Termux home not found at $TERMUX_HOME. Using $HOME/.termux instead."
        CONF_DIR="$HOME/.termux"
    fi
    mkdir -p "$CONF_DIR"

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

    clear
    echo -e "\033[1;36m"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║  \033[1;33m★\033[1;37m  Debian Proot Setup — Color Theme  \033[1;33m★\033[1;36m      ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m0.\033[0m \033[1;91m🔙 Back to Main Menu                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m1.\033[0m \033[1;92m🎨 Default                                \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m2.\033[0m \033[1;92m🧛 Dracula                                \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m3.\033[0m \033[1;92m🌑 One Dark                               \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m4.\033[0m \033[1;92m🪵 Gruvbox Dark                           \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m5.\033[0m \033[1;92m🌞 Solarized Light                        \033[1;34m│\033[0m"
    echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"
    read -p $'\033[1;36mChoice: \033[0m' choice

    if [ "$choice" == "0" ]; then info "↩ Returning to main menu..."; sleep 0.4; return 0; fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#OPTIONS[@]} )); then
        SELECTED="${OPTIONS[choice-1]}"
        echo "${THEMES[$SELECTED]}" > "$CONF_DIR/colors.properties"
        if command -v termux-reload-settings >/dev/null 2>&1; then
            termux-reload-settings
        elif [ -f "/data/data/com.termux/files/usr/bin/termux-reload-settings" ]; then
            /data/data/com.termux/files/usr/bin/termux-reload-settings
        else
            info "Theme applied. Reload Termux settings manually."
        fi
        log "Theme ${C_BOLD}$SELECTED${C_RESET} applied."
    else
        warn "Invalid selection."
    fi
}

gui_setup() {
    section "Desktop Environment (XFCE + VNC) Setup"
    execute "apt-get install -y xfce4 xfce4-goodies tigervnc-standalone-server" "Installing XFCE4 and TigerVNC"
    cat << 'EOF' > "/usr/local/bin/vnc-start"
#!/bin/bash
export DISPLAY=":1"
echo "Starting VNC Server on :1..."
if [ -f "$HOME/.vnc/pid" ]; then rm "$HOME/.vnc/pid"; fi
vncserver -kill :1 >/dev/null 2>&1
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -geometry 1280x720 -depth 24 -name "Debian" -xstartup "xfce4-session"
echo "VNC Started. Connect using address: localhost:5901"
EOF
    cat << 'EOF' > "/usr/local/bin/vnc-stop"
#!/bin/bash
export DISPLAY=":1"
echo "Stopping VNC Server..."
vncserver -kill :1
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1
echo "VNC Stopped."
EOF
    chmod +x "/usr/local/bin/vnc-start" "/usr/local/bin/vnc-stop"
    log "GUI Setup Complete."
    info "Run ${C_BOLD}vnc-start${C_RESET} to start the desktop."
    warn "You will need to set a VNC password on the first run."
}

backup_setup() {
    section "Backup & Restore (Proot Home)"
    clear
    echo -e "\033[1;36m"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║    \033[1;33m★\033[1;37m  Debian Proot Setup — Backup  \033[1;33m★\033[1;36m         ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m1.\033[0m \033[1;92m📤 Backup Home Directory                  \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m2.\033[0m \033[1;92m📥 Restore Home Directory                 \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m0.\033[0m \033[1;91m🔙 Back to Main Menu                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"
    read -p $'\033[1;36mChoice: \033[0m' choice

    BACKUP_DIR="/sdcard"
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "/sdcard not found. Saving to $HOME/backups instead."
        BACKUP_DIR="$HOME/backups" ; mkdir -p "$BACKUP_DIR"
    fi
    case "$choice" in
        1)
            BACKUP_FILE="$BACKUP_DIR/debian_home_backup_$(date +%Y%m%d).tar.gz"
            info "Backing up $HOME to $BACKUP_FILE (this may take a while)..."
            tar -czf "$BACKUP_FILE" --exclude='.cache' --exclude='backups' -C "$HOME" . &
            spinner $!
            wait $!
            if [ $? -eq 0 ]; then
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
    TERMUX_HOME="/data/data/com.termux/files/home"
    FONT_DIR="$TERMUX_HOME/.termux"
    if [ ! -d "$TERMUX_HOME" ]; then
        warn "Termux home not found at $TERMUX_HOME. Using $HOME/.termux instead."
        FONT_DIR="$HOME/.termux"
    fi
    mkdir -p "$FONT_DIR"

    # NOTE: nerd-fonts removed the old master/patched-fonts/*.ttf raw layout;
    # fonts are now published only as per-family zip archives on GitHub
    # Releases, which is why the previous raw URLs 404'd. Each entry below
    # is Name|release-zip-URL|ttf-filename-inside-the-zip.
    local NERD_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
    FONTS=(
        "FiraCode|$NERD_BASE/FiraCode.zip|FiraCodeNerdFont-Regular.ttf"
        "JetBrainsMono|$NERD_BASE/JetBrainsMono.zip|JetBrainsMonoNerdFont-Regular.ttf"
        "Meslo|$NERD_BASE/Meslo.zip|MesloLGSNerdFont-Regular.ttf"
        "Hack|$NERD_BASE/Hack.zip|HackNerdFont-Regular.ttf"
        "SourceCodePro|$NERD_BASE/SourceCodePro.zip|SauceCodeProNerdFont-Regular.ttf"
        "UbuntuMono|$NERD_BASE/UbuntuMono.zip|UbuntuMonoNerdFont-Regular.ttf"
        "CascadiaCode|$NERD_BASE/CascadiaCode.zip|CaskaydiaCoveNerdFont-Regular.ttf"
        "Agave|$NERD_BASE/Agave.zip|AgaveNerdFont-Regular.ttf"
        "Iosevka|$NERD_BASE/Iosevka.zip|IosevkaNerdFont-Regular.ttf"
    )
    DEFAULT_FONT="FiraCode"

    clear
    echo -e "\033[1;36m"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║  \033[1;33m★\033[1;37m  Debian Proot Setup — Nerd Fonts  \033[1;33m★\033[1;36m       ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║    \033[1;95mPress Enter for default: FiraCode\033[1;36m         ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m0.\033[0m \033[1;91m🔙 Back to Main Menu                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m1.\033[0m \033[1;92m✨ FiraCode                               \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m2.\033[0m \033[1;92m☕ JetBrainsMono                          \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m3.\033[0m \033[1;92m🟦 Meslo                                  \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m4.\033[0m \033[1;92m🔓 Hack                                   \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m5.\033[0m \033[1;92m📝 SourceCodePro                          \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m6.\033[0m \033[1;92m🐧 UbuntuMono                             \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m7.\033[0m \033[1;92m💫 CascadiaCode                           \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m8.\033[0m \033[1;92m🌀 Agave                                  \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m9.\033[0m \033[1;92m🎯 Iosevka                                \033[1;34m│\033[0m"
    echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"
    read -p $'\033[1;36mChoice: \033[0m' choice

    if [ "$choice" == "0" ]; then info "↩ Returning to main menu..."; sleep 0.4; return 0; fi
    SELECTED_URL="" ; SELECTED_NAME="" ; SELECTED_FILE=""
    if [ -z "$choice" ]; then
        SELECTED_NAME="$DEFAULT_FONT"
        SELECTED_URL=$(echo "${FONTS[0]}" | cut -d'|' -f2)
        SELECTED_FILE=$(echo "${FONTS[0]}" | cut -d'|' -f3)
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#FONTS[@]} )); then
        SELECTED_NAME=$(echo "${FONTS[choice-1]}" | cut -d'|' -f1)
        SELECTED_URL=$(echo "${FONTS[choice-1]}" | cut -d'|' -f2)
        SELECTED_FILE=$(echo "${FONTS[choice-1]}" | cut -d'|' -f3)
    else
        warn "Invalid selection, falling back to $DEFAULT_FONT"
        SELECTED_NAME="$DEFAULT_FONT"
        SELECTED_URL=$(echo "${FONTS[0]}" | cut -d'|' -f2)
        SELECTED_FILE=$(echo "${FONTS[0]}" | cut -d'|' -f3)
    fi
    check_internet
    command -v unzip >/dev/null 2>&1 || { info "Installing unzip..."; apt-get install -y unzip >/dev/null 2>&1 || pkg install -y unzip >/dev/null 2>&1; }
    TMP_ZIP="$FONT_DIR/.font_tmp.zip"
    execute "curl -fLo '$TMP_ZIP' '$SELECTED_URL'" "Downloading $SELECTED_NAME Nerd Font"
    execute "unzip -p '$TMP_ZIP' '$SELECTED_FILE' > '$FONT_DIR/font.ttf' && rm -f '$TMP_ZIP'" "Extracting $SELECTED_NAME Nerd Font"
    if command -v termux-reload-settings >/dev/null 2>&1; then
        termux-reload-settings
    elif [ -f "/data/data/com.termux/files/usr/bin/termux-reload-settings" ]; then
        /data/data/com.termux/files/usr/bin/termux-reload-settings
    else
        info "Font installed. Reload Termux settings manually."
    fi
    log "Font $SELECTED_NAME installed."
}

zsh_setup() {
    section "Zsh & Oh My Zsh Configuration"
    check_internet
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

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
fi

if [ -f "/usr/bin/lsd" ] || [ -f "/usr/local/bin/lsd" ]; then
    alias ls="lsd" ; alias ll="lsd -l" ; alias la="lsd -a"
else
    alias ls='ls --color=auto' ; alias ll='ls -alF' ; alias la='ls -A'
fi

if [ -f "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env"; fi
if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

touch ~/.hushlogin

if [ -f "/usr/local/bin/starship" ] || [ -f "/usr/bin/starship" ]; then
    eval "$(starship init zsh)"
fi

upload() {
  GREEN="\033[0;32m" ; YELLOW="\033[1;33m" ; RED="\033[0;31m" ; CYAN="\033[0;36m" ; RESET="\033[0m"
  echo -e "\n${CYAN}📦 Starting Git upload...${RESET}"
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a Git repository!${RESET}\n" ; return 1
  fi
  git add .
  MSG="${1:-Update}"
  if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to commit.${RESET}\n"
  else
    git commit -m "$MSG" && echo -e "${GREEN}✅ Committed: ${MSG}${RESET}\n" || { echo -e "${RED}❌ Commit failed.${RESET}\n" ; return 1; }
  fi
  if git remote | grep -q "^origin$"; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$BRANCH" && echo -e "${GREEN}🚀 Pushed to '${BRANCH}'!${RESET}\n" || echo -e "${RED}❌ Push failed.${RESET}\n"
  else
    echo -e "${YELLOW}⚠️  Remote 'origin' not found.${RESET}\n"
  fi
}
EOF
    log "Zsh + plugins configured."
}

starship_setup() {
    section "Starship Prompt Configuration"
    mkdir -p "$HOME/.config"
    PRESETS=("catppuccin-powerline" "gruvbox-rainbow" "tokyo-night" "pastel-powerline" "nerd-font-symbols" "bracketed-segments" "pure-preset" "jetpack")
    DEFAULT="catppuccin-powerline"

    clear
    echo -e "\033[1;36m"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║ \033[1;33m★\033[1;37m Debian Proot Setup — Starship Preset \033[1;33m★\033[1;36m     ║"
    echo -e "╠══════════════════════════════════════════════╣"
    echo -e "║ \033[1;95mPress Enter for default: catppuccin-powerline\033[1;36m║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m0.\033[0m \033[1;91m🔙 Back to Main Menu                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m1.\033[0m \033[1;92m🐱 catppuccin-powerline                   \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m2.\033[0m \033[1;92m🪨 gruvbox-rainbow                        \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m3.\033[0m \033[1;92m🌃 tokyo-night                            \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m4.\033[0m \033[1;92m🍬 pastel-powerline                       \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m5.\033[0m \033[1;92m🔣 nerd-font-symbols                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m6.\033[0m \033[1;92m🔲 bracketed-segments                     \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m7.\033[0m \033[1;92m🌿 pure-preset                            \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m8.\033[0m \033[1;92m🚄 jetpack                                \033[1;34m│\033[0m"
    echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"
    read -p $'\033[1;36mChoice: \033[0m' choice

    if [ "$choice" == "0" ]; then info "↩ Returning to main menu..."; sleep 0.4; return 0; fi
    if [ -z "$choice" ]; then
        CHOSEN="$DEFAULT"
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PRESETS[@]} )); then
        CHOSEN="${PRESETS[choice-1]}"
    else
        warn "Invalid selection, falling back to default: $DEFAULT"
        CHOSEN="$DEFAULT"
    fi
    info "Selected preset: ${C_BOLD}$CHOSEN${C_RESET}"
    if ([ -f "/usr/local/bin/starship" ] || [ -f "/usr/bin/starship" ]) && starship preset "$CHOSEN" -o "$HOME/.config/starship.toml"; then
        log "Starship configured with ${C_BOLD}$CHOSEN${C_RESET} ${C_GREEN}✔${C_RESET}"
    else
        warn "Starship not found or preset failed. Ensure Starship is installed."
    fi
}

post_setup() {
    section "Post-setup Starship Configuration"
    CFG="$HOME/.config/starship.toml"
    if [ ! -f "$CFG" ]; then warn "starship.toml not found at $CFG"; return 1; fi
    echo -e "\n${C_BOLD}${C_CYAN}🚀 Post-setup configuration for Starship prompt${C_RESET}\n"
    edit_key_in_section() {
        local section="$1" key="$2" value="$3"
        local section_header="\[$section\]" key_pattern="^\s*$key\s*="
        if ! grep -q "^$section_header" "$CFG"; then
            echo -e "  ${C_YELLOW}⚠️ Section [$section] not found. Skipping...${C_RESET}"; return 1
        fi
        if sed -n "/^$section_header/,/^\[/{ /$key_pattern/p }" "$CFG" | grep -q .; then
            sed -i "/^$section_header/,/^\[/{s/$key_pattern.*/$key = $value/}" "$CFG"
        else
            sed -i "/^$section_header/a $key = $value" "$CFG"
        fi
    }
    read -rp "$(printf "${C_CYAN}❓ command_timeout value (default 1000): ${C_RESET}")" cmd_timeout
    cmd_timeout="${cmd_timeout:-1000}"
    if grep -q "^command_timeout\s*=" "$CFG"; then
        sed -i "s/^command_timeout\s*=.*/command_timeout = $cmd_timeout/" "$CFG"
    else
        sed -i "1i command_timeout = $cmd_timeout" "$CFG"
    fi
    echo -e "  ${C_GREEN}⏱ command_timeout set to $cmd_timeout.${C_RESET}"
    read -rp "$(printf "${C_CYAN}❓ 12-hour AM/PM time format? (y/N): ${C_RESET}")" use_12h
    if [[ "$use_12h" =~ ^[Yy]$ ]]; then
        edit_key_in_section "time" "time_format" "\"%I:%M %p\"" && edit_key_in_section "time" "disabled" "false"
        echo -e "  ${C_GREEN}✅ 12-hour time format applied.${C_RESET}"
    else
        edit_key_in_section "time" "time_format" "\"%R\"" && edit_key_in_section "time" "disabled" "false"
        echo -e "  ${C_BLUE}⏰ 24-hour time format applied.${C_RESET}"
    fi
    read -rp "$(printf "${C_CYAN}❓ Two-liner prompt? (y/N): ${C_RESET}")" two_liner
    if [[ "$two_liner" =~ ^[Yy]$ ]]; then
        edit_key_in_section "line_break" "disabled" "false" && echo -e "  ${C_GREEN}✅ Two-liner prompt enabled.${C_RESET}"
    else
        edit_key_in_section "line_break" "disabled" "true" && echo -e "  ${C_BLUE}➡ Two-liner prompt disabled.${C_RESET}"
    fi
    read -rp "$(printf "${C_CYAN}❓ Show command duration? (y/N): ${C_RESET}")" show_duration
    if [[ "$show_duration" =~ ^[Yy]$ ]]; then
        edit_key_in_section "cmd_duration" "disabled" "false" && echo -e "  ${C_GREEN}✅ Command duration enabled.${C_RESET}"
    else
        edit_key_in_section "cmd_duration" "disabled" "true" && echo -e "  ${C_BLUE}➡ Command duration disabled.${C_RESET}"
    fi
    echo -e "\n${C_BOLD}${C_GREEN}🎉 Post-setup configuration complete!${C_RESET}\n"
}

git_setup() {
    section "Git & SSH Configuration"
    info "${C_CYAN}Enter your Git credentials (or press Enter to keep existing):${C_RESET}"
    echo
    echo -n -e "- ${C_YELLOW}Username [$(git config --global user.name)]:${C_RESET} " ; read gitname
    echo -n -e "- ${C_YELLOW}Email [$(git config --global user.email)]:${C_RESET} " ; read gitemail
    if [ -n "$gitname" ]; then git config --global user.name "$gitname"; fi
    if [ -n "$gitemail" ]; then git config --global user.email "$gitemail"; fi
    log "${C_GREEN}Git global user configuration updated.${C_RESET}"
    SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        info "${C_YELLOW}No existing ed25519 SSH key found. Generating a new one.${C_RESET}"
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        apt-get install -y openssh-client
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY_PATH" -N "" || error_exit "SSH Keygen failed."
    else
        info "${C_GREEN}Existing ed25519 SSH key found.${C_RESET}"
    fi
    eval "$(ssh-agent -s)" && ssh-add "$SSH_KEY_PATH"
    info "${C_BOLD}Your public SSH key:${C_RESET}"
    echo -e "${C_CYAN}" ; cat "$SSH_KEY_PATH.pub" ; echo -e "${C_RESET}"
    warn "${C_BOLD}Copy the key and add it to your GitHub account.${C_RESET}"
    read -p "Press [Enter] to test the connection..."
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1)
    if [[ "$SSH_OUTPUT" == *"successfully authenticated"* ]]; then
        log "${C_GREEN}GitHub SSH connection successful! ✔${C_RESET}"
    else
        warn "GitHub SSH connection failed. Add your key at: https://github.com/settings/keys"
    fi
}

switch_shell() {
    section "Switching Default Shell"
    if $SUDO chsh -s /usr/bin/zsh "$USER"; then
        log "Default shell set to Zsh for $USER. Run 'exit' and log back in to apply."
    else
        error_exit "'chsh' failed. Run 'which zsh' to confirm path, or check permissions."
    fi
}

dev_setup() {
    section "Software & Development Setup (Debian)"
    clear
    echo -e "\033[1;36m"
    echo -e "╔══════════════════════════════════════════════╗"
    echo -e "║   \033[1;33m★\033[1;37m  Debian Proot Setup — Dev Tools  \033[1;33m★\033[1;36m       ║"
    echo -e "╚══════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;34m┌──────────────────────────────────────────────┐\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m1.\033[0m \033[1;92m🔧 Basic Tools (lsd, htop, micro, etc.)   \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m2.\033[0m \033[1;92m🐍 Python (python3, pip, venv, uv)        \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m3.\033[0m \033[1;92m🟩 Node.js (via fnm)                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m4.\033[0m \033[1;92m🦀 Rust (via rustup)                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m5.\033[0m \033[1;92m📝 Neovim & Tmux                          \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m6.\033[0m \033[1;95m⚡ All of the above                       \033[1;34m│\033[0m"
    echo -e "\033[1;34m│\033[0m \033[1;37m0.\033[0m \033[1;91m🔙 Back to Main Menu                      \033[1;34m│\033[0m"
    echo -e "\033[1;34m└──────────────────────────────────────────────┘\033[0m"
    read -p $'\033[1;36mChoice: \033[0m' choice
    case "$choice" in
        1) tools_setup ;;
        2) install_pkg "python3" ; install_pkg "python3-pip" ; install_pkg "python3-venv"
           execute "pip3 install uv --break-system-packages" "Installing 'uv'" || execute "pip3 install uv" "Installing 'uv' (fallback)" ;;
        3) execute "curl -fsSL https://fnm.vercel.app/install | bash" "Installing fnm"
           info "Please restart shell or source your rc file." ;;
        4) execute "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "Installing rustup" ;;
        5) install_pkg "neovim" ; install_pkg "tmux" ;;
        6) check_internet
           tools_setup
           install_pkg "python3" ; install_pkg "python3-pip" ; install_pkg "python3-venv"
           execute "pip3 install uv --break-system-packages" "Installing 'uv'" || execute "pip3 install uv" "Installing 'uv'"
           execute "curl -fsSL https://fnm.vercel.app/install | bash" "Installing fnm"
           execute "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" "Installing rustup"
           install_pkg "neovim" ; install_pkg "tmux" ;;
        0) info "↩ Returning to main menu..."; sleep 0.4; return ;;
        *) warn "Invalid choice" ;;
    esac
}

run_all() {
    echo -e "\n\033[1;33m⚠  Full Setup will: update packages, install tools, overwrite .zshrc,"
    echo -e "   set Starship prompt, install a font, and switch your shell to Zsh.\033[0m"
    read -rp $'\033[1;36mProceed? (y/N): \033[0m' _confirm
    if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
        info "Full setup cancelled."
        return 0
    fi
    base_setup ; tools_setup ; font_setup ; zsh_setup ; starship_setup ; post_setup ; switch_shell
}

interactive_menu() {
    main_banner

    while true; do
        clear
        echo -e "[1;36m"
        echo -e "╔══════════════════════════════════════════════╗"
        echo -e "║  [1;33m★[1;37m Debian Proot Setup Tool by sms1sis [1;33m★[1;36m      ║"
        echo -e "╠══════════════════════════════════════════════╣"
        echo -e "║      [1;95mWelcome — Choose an option to begin     [1;36m║"
        echo -e "╚══════════════════════════════════════════════╝"
        echo -e "[0m"
    echo -e "[1;34m┌──────────────────────────────────────────────┐[0m"
    echo -e "[1;34m│[0m [1;37m 1.[0m [1;92m🚀 Full Setup (Run Everything)           [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 2.[0m [1;92m🔄 Base System Setup (Update/Upgrade)    [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 3.[0m [1;92m🐚 Configure Zsh & Oh My Zsh             [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 4.[0m [1;92m⭐ Configure Starship Prompt             [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 5.[0m [1;92m🔤 Install Nerd Fonts                    [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 6.[0m [1;92m🎨 Configure Terminal Theme              [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 7.[0m [1;92m🔀 Switch Default Shell to Zsh           [1;34m│[0m"
    echo -e "[1;34m│                                              │[0m"
    echo -e "[1;34m│[1;95m            ★ Optional Features ★             [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 8.[0m [1;92m🔩 Software & Development Setup          [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 9.[0m [1;92m💻 Setup GUI (XFCE + VNC)                [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m10.[0m [1;92m💾 Backup & Restore                      [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m11.[0m [1;92m🔑 Configure Git & SSH Keys              [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m12.[0m [1;92m🔁 Check for Updates                     [1;34m│[0m"
    echo -e "[1;34m│[0m [1;37m 0.[0m [1;91m❌ Exit                                  [1;34m│[0m"
    echo -e "[1;34m│                                              │[0m"
    echo -e "[1;34m└──────────────────────────────────────────────┘[0m"
        read -p $'[1;36mChoice: [0m' menu_choice

        case "$menu_choice" in
            1) run_all ;; 2) base_setup ;; 3) zsh_setup ;;
            4) starship_setup && post_setup ;; 5) font_setup ;; 6) theme_setup ;;
            7) switch_shell ;; 8) dev_setup ;; 9) gui_setup ;;
            10) backup_setup ;; 11) git_setup ;; 12) self_update ;;
            0) echo -e "
[1;32mGoodbye! Thanks for using Debian Proot Setup![0m"; exit 0 ;;
            *) warn "Invalid option, please try again."; sleep 1; continue ;;
        esac
    done
}

main() {
    if [ $# -eq 0 ]; then interactive_menu; return; fi
    main_banner ; RUN_SWITCH=0
    for arg in "$@"; do
        case "$arg" in
            base) base_setup ;; tools) tools_setup ;; theme) theme_setup ;;
            gui) gui_setup ;; backup) backup_setup ;; font) font_setup ;;
            zsh) zsh_setup ;; starship) starship_setup ;; post) post_setup ;;
            git) git_setup ;; all) run_all ;; --switch) RUN_SWITCH=1 ;;
            --switch-now) exec zsh ;;
            *) echo "Usage: $0 {base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"; return 1 ;;
        esac
    done
    if [ "$RUN_SWITCH" -ne 0 ]; then switch_shell; fi
}

main "$@"
