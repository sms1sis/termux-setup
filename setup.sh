#!/data/data/com.termux/files/usr/bin/bash
# Termux Unified Setup Script

set -euo pipefail
LOGFILE="$HOME/termux_setup.log"

log() { echo -e "[*] $1" | tee -a "$LOGFILE"; }
error_exit() { echo -e "[!] $1" | tee -a "$LOGFILE"; exit 1; }

install_pkg() {
    local pkg=$1
    # Use 'command -v' for POSIX compliance
    if ! command -v "$pkg" >/dev/null 2>&1; then
        log "Installing $pkg..."
        pkg install -y "$pkg" || error_exit "Failed to install $pkg"
    else
        log "$pkg already installed, skipping."
    fi
}

backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%s)"
        log "Backed up $file"
    fi
}

# --- Subcommands ---
storage_setup() {
    log "Requesting storage access..."
    termux-setup-storage || log "Storage permission already granted or command failed."
}

base_setup() {
    log "Running base setup..."
    pkg update -y && pkg upgrade -y
    for p in git curl wget zsh; do install_pkg "$p"; done
    log "Base setup complete."
}

tools_setup() {
    log "Installing utilities..."
    for p in lsd htop tsu unzip micro which openssh; do install_pkg "$p"; done
    log "Utilities installed."
}

font_setup() {
    log "Installing FiraCode Nerd Font..."
    mkdir -p "$HOME/.termux"
    curl -fLo "$HOME/.termux/font.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
    termux-reload-settings
    log "Font installed and settings reloaded."
}

zsh_setup() {
    log "Setting up Oh My Zsh and plugins..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        export RUNZSH=no
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || error_exit "Oh My Zsh install failed"
    else
        log "Oh My Zsh already installed, skipping."
    fi

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    # Install plugins
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    fi

    backup_file "$HOME/.zshrc"
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
    log "Configuring Starship..."
    if ! command -v starship >/dev/null 2>&1; then
        curl -fsSL https://starship.rs/install.sh | bash -s -- -y || error_exit "Starship install failed"
    fi
    mkdir -p "$HOME/.config"
    starship preset catppuccin-powerline -o ~/.config/starship.toml
    log "Starship configured with catppuccin-powerline preset."
}

git_setup() {
    log "Configuring Git + SSH..."
    read -p "Enter your Git username: " gitname
    read -p "Enter your Git email: " gitemail
    git config --global user.name "$gitname"
    git config --global user.email "$gitemail"

    SSH_KEY="$HOME/.ssh/id_ed25519" # Using ed25519 as it's more modern
    if [ ! -f "$SSH_KEY" ]; then
        ssh-keygen -t ed25519 -C "$gitemail" -f "$SSH_KEY" -N ""
        log "Generated ed25519 SSH key."
    else
        log "SSH key already exists, skipping."
    fi
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    log "Git setup complete. Copy this key to GitHub:"
    cat "$SSH_KEY.pub"
    read -p "Press [Enter] after adding your SSH key to GitHub to test the connection..."
    log "Testing SSH connection to GitHub..."
    ssh -T git@github.com
}

switch_shell() {
    log "Setting Zsh as default shell for next login..."
    chsh -s zsh || log "chsh not available, fallback: add 'exec zsh' to ~/.bashrc"
}

switch_now() {
    log "Switching to Zsh immediately..."
    exec zsh
}

post_setup() {
    log "Running post-setup (Starship)..."
    local CFG="$HOME/.config/starship.toml"
    if [ ! -f "$CFG" ]; then
        mkdir -p "$HOME/.config"
        starship preset catppuccin-powerline -o "$CFG"
        log "Created default starship.toml"
    fi
    backup_file "$CFG"

    echo "Choose a Starship preset (or press Enter to skip):"
    options=("catppuccin-powerline" "tokyo-night" "gruvbox-rainbow" "none")
    select opt in "${options[@]}"; do
        if [[ "$opt" != "none" && -n "$opt" ]]; then
            starship preset "$opt" -o "$CFG"
            log "Applied $opt preset to starship.toml"
        fi
        break
    done

    read -rp "Enter command_timeout value (default 1000): " cmd_timeout
    sed -i "1i command_timeout = ${cmd_timeout:-1000}" "$CFG"

    read -rp "Use 12-hour AM/PM time format? (y/N): " use_12h
    if [[ "$use_12h" =~ ^[Yy]$ ]]; then
        sed -i '/\[time\]/a time_format = "%I:%M %p"' "$CFG"
        log "Set 12-hour time format."
    fi
}

# --- Dispatcher ---
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
    --switch-now) switch_now ;;
    *)
        echo "Usage: $0 {storage|base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"
        ;;
esac
