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
pkg install -y zsh git curl lsd starship htop tsu unzip

# 3. Install a Nerd Font (FiraCode)
echo "✒️  Installing FiraCode Nerd Font..."
mkdir -p ~/.termux
curl -fLo "$HOME/.termux/font.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf

# 4. Install Oh My Zsh (non-interactively)
echo "😎 Installing Oh My Zsh..."
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


# IMPORTANT: Add your Gemini API key here if you need it.
# export GEMINI_API_KEY="YOUR_API_KEY_HERE"

eval "$(starship init zsh)"
EOF

# 7. Configure Starship prompt
echo "✨ Configuring Starship prompt..."
if command -v starship >/dev/null 2>&1; then
  if starship preset --help >/dev/null 2>&1; then
    starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"
  else
    echo "⚠️  starship preset not supported by this version; creating minimal config..."
    mkdir -p "$HOME/.config"
    echo 'add_newline = false' > "$HOME/.config/starship.toml"
  fi

  # Ensure command_timeout is set to 100
  CFG="$HOME/.config/starship.toml"
  if grep -q '^command_timeout' "$CFG" 2>/dev/null; then
    sed -i 's/^command_timeout.*/command_timeout = 100/' "$CFG"
  else
    echo '' >> "$CFG"
    echo 'command_timeout = 100' >> "$CFG"
  fi
else
  echo "⚠️  starship not installed; skipping preset and timeout configuration."
fi



# 8. Create the time-fixing helper script
echo "🕒 Creating the fix_starship_time.sh helper script..."
cat > ~/fix_starship_time.sh << 'EOF'
#!/bin/bash
# This script automatically changes the time format in the starship.toml file to 12-hour AM/PM format.

CONFIG_FILE="$HOME/.config/starship.toml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: starship.toml not found at $CONFIG_FILE"
  exit 1
fi

if grep -q '^time_format' "$CONFIG_FILE"; then
  sed -i 's/^time_format.*/time_format = "%I:%M %p"/' "$CONFIG_FILE"
  echo "✅ Time format updated to 12-hour."
elif grep -q '^\[time\]' "$CONFIG_FILE"; then
  sed -i '/^\[time\]/a time_format = "%I:%M %p"' "$CONFIG_FILE"
  echo "✅ Time format added to existing [time] section."
else
  # add [time] section if missing
  echo -e "\n[time]\
time_format = \"%I:%M %p\"" >> "$CONFIG_FILE"
  echo "✅ [time] section created and time_format set to 12-hour."
fi
EOF
chmod +x ~/fix_starship_time.sh

# 9. Disable the Termux welcome message
echo "🤫 Disabling the Termux welcome message..."
touch ~/.hushlogin

# 10. Final instructions
echo ""
echo "✅ All done! Reloading Termux settings to apply the new font..."
termux-reload-settings

echo ""
echo "IMPORTANT: To make Zsh your default shell, please run this final command manually:"
echo ""
echo "  chsh -s zsh"
echo ""
echo "After that, close and reopen Termux to see all the changes."
