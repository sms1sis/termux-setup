#!/data/data/com.termux/files/usr/bin/bash
# Termux Unified Setup Script

# --- Boilerplate and Utilities ---
set -euo pipefail
LOGFILE="$HOME/termux_setup.log"

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'
C_UNDERLINE='\033[4m'

# --- Logging Functions ---
log()     { echo -e "${C_GREEN}[✔]${C_RESET} $1" | tee -a "$LOGFILE"; }
warn()    { echo -e "${C_YELLOW}[!]${C_RESET} $1" | tee -a "$LOGFILE"; }
error_exit() { echo -e "${C_RED}[✖]${C_RESET} $1" | tee -a "$LOGFILE"; exit 1; }
info()    { echo -e "${C_CYAN}[i]${C_RESET} $1" | tee -a "$LOGFILE"; }
section() { echo -e "\n${C_MAGENTA}✨ ${C_BOLD}$1${C_RESET}\n"; }

# --- Helper Functions ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%???}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

execute() {
    local cmd=$1
    local msg=$2
    info "$msg"
    sh -c "$cmd" &> "$LOGFILE" &
    spinner $!
    wait $!
    if [ $? -eq 0 ]; then
        log "$msg - Done"
    else
        error_exit "$msg - Failed"
    fi
}

install_pkg() {
    local pkg=$1
    if ! command -v "$pkg" >/dev/null 2>&1; then
        execute "pkg install -y $pkg" "Installing $pkg"
    else
        info "$pkg already installed, skipping."
    fi
}

backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%s)"
        info "Backed up $file"
    fi
}

# --- Main Setup Functions ---
main_banner() {
    echo -e "${C_BLUE}${C_BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║          🚀 Termux Unified Setup Script 🚀                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
}

storage_setup() {
    section "Storage Setup"
    info "Requesting storage access..."
    termux-setup-storage || warn "Storage permission already granted or command failed."
}

base_setup() {
    section "Base System Setup"
    execute "pkg update -y && pkg upgrade -y" "Updating and upgrading packages"
    for p in git curl wget zsh starship; do install_pkg "$p"; done
    log "Base setup complete."
}

tools_setup() {
    section "Development Tools Installation"
    for p in lsd htop tsu unzip micro which openssh; do install_pkg "$p"; done
    log "Utilities installed."
}

font_setup() {
    section "Font Installation"
    mkdir -p "$HOME/.termux"
    execute "curl -fLo $HOME/.termux/font.ttf https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf" "Installing FiraCode Nerd Font"
    termux-reload-settings
    log "Font installed and settings reloaded."
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
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
alias ls="lsd"
touch ~/.hushlogin
eval "$(starship init zsh)"

# Git quick upload helper
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
  MSG="${1:-Update}"
  if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️ No changes to commit.${RESET}\n"
  else
    git commit -m "$MSG"
    git push
    echo -e "${GREEN}✅ Successfully committed and pushed.${RESET}\n"
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
    echo -e "${C_MAGENTA}${C_BOLD}🎨 Choose a Starship preset${C_RESET}  ${C_CYAN}(press Enter for default: ${C_BOLD}$DEFAULT${C_RESET}${C_CYAN})${C_RESET}"
    echo
    for i in "${!PRESETS[@]}"; do
        idx=$((i+1))
        echo -e "  ${C_YELLOW}$idx)${C_RESET} ${C_BLUE}${PRESETS[i]}${C_RESET}"
    done
    echo
    echo -n -e "${C_CYAN}Selection ${C_RESET}> "
    read -r choice
    echo

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

    if starship preset "$CHOSEN" -o "$HOME/.config/starship.toml"; then
        log "Starship configured with ${C_BOLD}$CHOSEN${C_RESET} ${C_GREEN}✔${C_RESET}"
    else
        warn "Failed to apply preset $CHOSEN. You can run: starship preset $CHOSEN -o ~/.config/starship.toml"
    fi
}

git_setup() {
    section "Git & SSH Configuration"
    info "Please enter your Git credentials:"
    read -p "- Username: " gitname
    read -p "- Email: " gitemail
    git config --global user.name "$gitname"
    git config --global user.email "$gitemail"

    SSH_KEY="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_KEY" ]; then
        execute "ssh-keygen -t ed25519 -C '$gitemail' -f $SSH_KEY -N ''" "Generating ed25519 SSH key"
    else
        info "SSH key already exists."
    fi
    
    info "Adding SSH key to the agent..."
    eval "$(ssh-agent -s)" &> /dev/null
    ssh-add "$SSH_KEY"
    
    info "${C_BOLD}Your public SSH key:${C_RESET}"
    cat "$SSH_KEY.pub"
    warn "Please copy the key above and add it to your GitHub account."
    read -p "Press [Enter] to test the SSH connection to GitHub..."
    ssh -T git@github.com || warn "SSH connection test failed. Please ensure your key is added to GitHub."
}

post_setup() {
    # --- Color Definitions (local) ---
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    RED='\033[0;31m'
    NC='\033[0m'

    CFG="$HOME/.config/starship.toml"

    if [ ! -f "$CFG" ]; then
        echo -e "${RED}❌ starship.toml not found at $CFG${NC}"
        return 1
    fi

    echo -e "\n${BOLD}${CYAN}🚀 Post-setup configuration for Starship prompt${NC}\n"

    # Helper: ensure section exists (create if missing)
    ensure_section() {
        local section="$1"
        if ! grep -qE "^\[$section\]" "$CFG"; then
            printf "\n[%s]\n" "$section" >> "$CFG"
            echo -e "  ${YELLOW}➕ Added missing section [$section] to $CFG${NC}"
        fi
    }

    # Helper: set or add key within section (safe, handles end-of-file)
    edit_key_in_section() {
        local section="$1" key="$2" value="$3"
        local escaped_key
        escaped_key=$(printf '%s' "$key" | sed -e 's/[][\/.^$*]/\\&/g')

        ensure_section "$section"

        # If key exists in section, replace it; otherwise append after section header
        if awk -v sec="[$section]" -v key="$key" '
            $0 ~ "^"sec { insec=1; next }
            insec && $0 ~ "^\\[" { exit 2 } # end of section
            insec && $0 ~ "^[[:space:]]*"key"[[:space:]]*=" { found=1; print NR; exit 0 }
            END { if (found) exit 0; if (insec) exit 3; exit 4 }
        ' "$CFG"; then
            # Replace existing key in section
            sed -i "/^\[$section\]/, /^\[/ s/^[[:space:]]*$escaped_key[[:space:]]*=.*/$key = $value/" "$CFG"
        else
            # Append key right after the section header
            sed -i "/^\[$section\]/ a $key = $value" "$CFG"
        fi
        return 0
    }

    # 1. command_timeout
    read -rp "$(printf "${YELLOW}❓ Enter command_timeout value (default 1000): ${NC}")" cmd_timeout
    cmd_timeout="${cmd_timeout:-1000}"

    if grep -qE "^command_timeout[[:space:]]*=" "$CFG"; then
        sed -i "s/^command_timeout[[:space:]]*=.*/command_timeout = $cmd_timeout/" "$CFG"
    else
        # insert at top for visibility
        sed -i "1i command_timeout = $cmd_timeout" "$CFG"
    fi
    echo -e "  ${GREEN}⏱ command_timeout set to $cmd_timeout.${NC}"

    # 2. 12-hour time
    read -rp "$(printf "${YELLOW}❓ Do you want 12-hour AM/PM time format? (y/N): ${NC}")" use_12h
    if [[ "$use_12h" =~ ^[Yy]$ ]]; then
        edit_key_in_section "time" "time_format" '"%I:%M %p"'
        edit_key_in_section "time" "disabled" "false"
        echo -e "  ${GREEN}✅ 12-hour time format applied.${NC}"
    else
        edit_key_in_section "time" "time_format" '"%R"'
        edit_key_in_section "time" "disabled" "false"
        echo -e "  ${BLUE}⏰ 24-hour time format applied.${NC}"
    fi

    # 3. two-liner prompt
    read -rp "$(printf "${YELLOW}❓ Do you want a two-liner prompt? (y/N): ${NC}")" two_liner
    if [[ "$two_liner" =~ ^[Yy]$ ]]; then
        edit_key_in_section "line_break" "disabled" "false"
        echo -e "  ${GREEN}✅ Two-liner prompt enabled.${NC}"
    else
        edit_key_in_section "line_break" "disabled" "true"
        echo -e "  ${BLUE}➡ Two-liner prompt disabled.${NC}"
    fi

    # 4. show command duration
    read -rp "$(printf "${YELLOW}❓ Do you want to show command duration? (y/N): ${NC}")" show_duration
    if [[ "$show_duration" =~ ^[Yy]$ ]]; then
        edit_key_in_section "cmd_duration" "disabled" "false"
        echo -e "  ${GREEN}✅ Command duration enabled.${NC}"
    else
        edit_key_in_section "cmd_duration" "disabled" "true"
        echo -e "  ${BLUE}➡ Command duration disabled.${NC}"
    fi

    echo -e "\n${BOLD}${GREEN}🎉 Post-setup configuration complete!${NC}\n"
    return 0
}

switch_shell() {
    section "Switching Default Shell"
    if chsh -s zsh; then
        log "Default shell set to Zsh. Please restart Termux."
    else
        warn "'chsh' command failed. Add 'exec zsh' to your ~/.bashrc manually."
    fi
}

# --- Dispatcher ---
main() {
    main_banner
    if [ $# -eq 0 ]; then
        info "No command specified. Running 'all' by default."
        all
        return
    fi

    case "${1:-}" in
        storage) storage_setup ;; 
        base) base_setup ;; 
        tools) tools_setup ;; 
        font) font_setup ;; 
        zsh) zsh_setup ;; 
        starship) starship_setup ;; 
        git) git_setup ;; 
        post) post_setup ;; 
        all) storage_setup; base_setup; tools_setup; font_setup; zsh_setup; starship_setup; git_setup; post_setup ;; 
        --switch) switch_shell ;; 
        --switch-now) exec zsh ;; 
        *) 
            echo "Usage: $0 {storage|base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"
            ;; 
    esac
}

main "$@"
