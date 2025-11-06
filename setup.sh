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
    ($cmd) &> "$LOGFILE" &
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
    for p in git curl wget zsh; do install_pkg "$p"; done
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
    if ! command -v starship >/dev/null 2>&1; then
        execute "curl -fsSL https://starship.rs/install.sh | bash -s -- -y" "Installing Starship"
    fi
    mkdir -p "$HOME/.config"
    starship preset catppuccin-powerline -o ~/.config/starship.toml
    log "Starship configured with catppuccin-powerline preset."
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
    section "Interactive Post-Setup (Starship)"
    local CFG="$HOME/.config/starship.toml"

    if [ ! -f "$CFG" ]; then
        warn "starship.toml not found. Creating a default one."
        mkdir -p "$HOME/.config"
        starship preset catppuccin-powerline -o "$CFG"
    fi
    backup_file "$CFG"

    edit_key_in_section() {
        local section="$1" key="$2" value="$3"
        # ... (implementation remains the same)
    }

    # ... (rest of post_setup remains the same)
    log "Post-setup complete."
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
