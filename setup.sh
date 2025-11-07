#!/data/data/com.termux/files/usr/bin/bash
# Termux Unified Setup Script

# --- Boilerplate and Utilities ---
set -uo pipefail
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
    echo "║             🚀 Termux Unified Setup Script 🚀              ║"
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
    read -rp "$(printf "${C_YELLOW}❓ Enter command_timeout value (default 100): ${C_RESET}")" cmd_timeout
    cmd_timeout="${cmd_timeout:-100}"

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
    read -rp "$(printf "${C_YELLOW}❓ Do you want 12-hour AM/PM time format? (y/N): ${C_RESET}")" use_12h
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
    read -rp "$(printf "${C_YELLOW}❓ Do you want a two-liner prompt? (y/N): ${C_RESET}")" two_liner
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
    read -rp "$(printf "${C_YELLOW}❓ Do you want to show command duration? (y/N): ${C_RESET}")" show_duration
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

    if [ -n "$gitname" ]; then git config --global user.name "$gitname"; fi
    if [ -n "$gitemail" ]; then git config --global user.email "$gitemail"; fi
    log "${C_GREEN}Git global user configuration updated.${C_RESET}"

    SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        info "${C_YELLOW}No existing ed25519 SSH key found. Generating a new one.${C_RESET}"
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY_PATH" -N ""
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
        error_exit "${C_RED}GitHub SSH connection failed. Manually verify your key.${C_RESET}"
    fi

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

    # Track whether we should run switch_shell at the end
    RUN_SWITCH=0

    # Iterate all arguments in order
    for arg in "$@"; do
        case "$arg" in
            storage) storage_setup ;;
            base) base_setup ;;
            tools) tools_setup ;;
            font) font_setup ;;
            zsh) zsh_setup ;;
            starship) starship_setup ;;
            post) post_setup ;;
            git) git_setup ;;
            all)
                storage_setup
                base_setup
                tools_setup
                font_setup
                zsh_setup
                starship_setup
                post_setup
                git_setup
                ;;
            --switch)
                # Defer switch until after other requested work
                RUN_SWITCH=1
                ;;
            --switch-now)
                exec zsh
                ;;
            *)
                echo "Usage: $0 {storage|base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"
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
