#!/data/data/com.termux/files/usr/bin/bash
# Termux Unified Setup Script

set -euo pipefail
LOGFILE="$HOME/termux_setup.log"

log() { echo -e "[*] $1" | tee -a "$LOGFILE"; }
error_exit() { echo -e "[!] $1" | tee -a "$LOGFILE"; exit 1; }

install_pkg() {
    local pkg=$1
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
base_setup() {
    log "Running base setup..."
    pkg update -y && pkg upgrade -y
    for p in git curl wget zsh; do install_pkg "$p"; done
    log "Base setup complete."
}

tools_setup() {
    log "Installing utilities..."
    for p in lsd htop tsu unzip micro which; do install_pkg "$p"; done
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

    SSH_KEY="$HOME/.ssh/id_rsa"
    if [ ! -f "$SSH_KEY" ]; then
        ssh-keygen -t rsa -b 4096 -C "$gitemail" -f "$SSH_KEY" -N ""
        log "Generated SSH key."
    else
        log "SSH key already exists, skipping."
    fi
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY"
    log "Git setup complete. Copy this key to GitHub:"
    cat "$SSH_KEY.pub"
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
    log "Running post-setup (Starship presets)..."
    mkdir -p "$HOME/.config"

    local STARSHIP_FILE="$HOME/.config/starship.toml"
    backup_file "$STARSHIP_FILE"

    echo "Choose a Starship preset:"
    options=("catppuccin-powerline" "tokyo-night" "gruvbox-rainbow")
    select opt in "${options[@]}"; do
        starship preset "$opt" -o "$STARSHIP_FILE"
        log "Applied $opt preset to starship.toml"
        break
    done
}

# --- Dispatcher ---
case "${1:-}" in
    base) base_setup ;;
    tools) tools_setup ;;
    font) font_setup ;;
    zsh) zsh_setup ;;
    starship) starship_setup ;;
    git) git_setup ;;
    post) post_setup ;;
    all) base_setup; tools_setup; font_setup; zsh_setup; starship_setup; git_setup; post_setup ;;
    --switch) switch_shell ;;
    --switch-now) switch_now ;;
    *)
        echo "Usage: $0 {base|tools|font|zsh|starship|git|post|all|--switch|--switch-now}"
        ;;
esac
