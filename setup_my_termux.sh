#!/bin/bash
# A comprehensive script to set up a complete Zsh + Starship environment on a fresh Termux install.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting comprehensive Termux setup..."

# 1. Request Storage Access
echo "📁 Requesting access to shared storage..."
if ! termux-setup-storage; then
  echo "⚠️  termux-setup-storage returned non-zero; ensure storage permission manually if needed."
fi

# 2. Update packages and install all dependencies
echo "📦 Installing packages: zsh, git, curl, lsd, starship, htop, tsu, unzip..."
pkg update -y && pkg upgrade -y
pkg install -y zsh git curl lsd starship htop tsu unzip which micro

# 3. Install a Nerd Font (FiraCode)
echo "✒️  Installing FiraCode Nerd Font..."
mkdir -p ~/.termux
curl -fLo "$HOME/.termux/font.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf

# 4. Install Oh My Zsh (non-interactively)
echo "😎 Installing Oh My Zsh..."
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 5. Install Oh My Zsh plugins
echo "🧩 Installing zsh plugins (autosuggestions and syntax-highlighting)..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

# 6. Create the .zshrc file from scratch (with the upload function)
echo "✍️  Creating .zshrc configuration..."
cat > ~/.zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
alias ls="lsd"
touch ~/.hushlogin
eval "$(starship init zsh)"
EOF

# 7. Configure Starship prompt and helper scripts
echo "✨ Configuring Starship prompt..."
starship preset catppuccin-powerline -o ~/.config/starship.toml
echo ""
echo "✅ All done! Reloading Termux settings to apply the new font..."
termux-reload-settings
chsh -s zsh
exec zsh
