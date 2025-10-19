#!/bin/bash
# A comprehensive script to set up a complete Zsh + Starship environment on a fresh Termux install.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting comprehensive Termux setup..."

# 1. Request Storage Access
echo "📁 Requesting access to shared storage..."
termux-setup-storage

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
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
alias ls="lsd"

# 🧠 Git quick upload helper for Zsh with color messages
upload() {
  # Define color codes
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  RED="\033[0;31m"
  RESET="\033[0m"

  # Check if we’re inside a git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a Git repository!${RESET}"
    return 1
  fi

  # Stage all changes
  git add .
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to stage files.${RESET}"
    return 1
  fi

  # Use provided commit message or fallback
  MSG="${1:-Update}"

  # Commit changes
  if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to commit.${RESET}"
  else
    git commit -m "$MSG" >/dev/null 2>&1
    echo -e "${GREEN}✅ Committed: ${MSG}${RESET}"
  fi

  # Push to current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if git push origin "$CURRENT_BRANCH"; then
    echo -e "${GREEN}🚀 Pushed successfully to branch '${CURRENT_BRANCH}'!${RESET}"
  else
    echo -e "${RED}❌ Push failed.${RESET}"
  fi
}

# IMPORTANT: Add your Gemini API key here if you need it.
# export GEMINI_API_KEY="YOUR_API_KEY_HERE"

eval "$(starship init zsh)"
EOF

# 7. Apply the 'gruvbox-rainbow' Starship preset
echo "✨ Applying the 'gruvbox-rainbow' Starship preset..."
mkdir -p ~/.config
starship preset gruvbox-rainbow -o ~/.config/starship.toml
echo "🎨 You can customize the prompt by editing ~/.config/starship.toml"
echo "🎨 or find more presets at https://starship.rs/presets/"


# 9. Create the time-fixing helper script
echo "🕒 Creating the fix_starship_time.sh helper script..."
cat > ~/fix_starship_time.sh << 'EOF'
#!/bin/bash
# This script automatically changes the time format in the starship.toml file to 12-hour AM/PM format.

CONFIG_FILE="$HOME/.config/starship.toml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: starship.toml not found at $CONFIG_FILE"
  exit 1
fi

if grep -q 'time_format' "$CONFIG_FILE"; then
  sed -i 's/time_format = .*/time_format = "%I:%M %p"/' "$CONFIG_FILE"
  echo "✅ Time format updated to 12-hour."
else
  if grep -q '\[time\]' "$CONFIG_FILE"; then
    sed -i '/^\[time\]/a time_format = "%I:%M %p"' "$CONFIG_FILE"
    echo "✅ Time format added and set to 12-hour."
  else
    echo "⚠️  Warning: [time] section not found. Could not set time format."
  fi
fi
EOF
chmod +x ~/fix_starship_time.sh

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
