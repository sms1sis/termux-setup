#!/bin/bash
# ==============================================================
# 🌟 FULL GIT + GITHUB SSH SETUP FOR TERMUX (Colorful Edition)
# ==============================================================

# Define color codes
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"

# Pretty divider
divider() { echo -e "${DIM}${CYAN}──────────────────────────────────────────────${RESET}\n"; }

clear
echo -e "${BOLD}${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║      🚀 GIT + GITHUB SSH SETUP FOR TERMUX     ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${RESET}\n"

# 🧩 STEP 1: Update and install required packages
divider
echo -e "${BOLD}${YELLOW}🧩 STEP 1: Installing dependencies...${RESET}\n"
pkg update -y && pkg upgrade -y
pkg install git openssh -y
echo -e "${GREEN}✅ Git and OpenSSH installed successfully!${RESET}\n"

# 🧠 STEP 2: Configure Git identity
divider
echo -e "${BOLD}${YELLOW}🧠 STEP 2: Configuring Git identity...${RESET}\n"
read -p "🪪 Enter your Git user name: " git_user_name
git config --global user.name "$git_user_name"

read -p "📧 Enter your Git user email: " git_user_email
git config --global user.email "$git_user_email"

echo -e "\n${GREEN}✅ Git identity configured successfully!${RESET}\n"

# 🔑 STEP 3: Generate SSH key
divider
echo -e "${BOLD}${YELLOW}🔑 STEP 3: Generating SSH key...${RESET}\n"
ssh-keygen -t ed25519 -C "$git_user_email" -f ~/.ssh/id_ed25519 -N ""
echo -e "\n${GREEN}✅ SSH key created successfully!${RESET}\n"

# ⚙️ STEP 4: Start ssh-agent and add key
divider
echo -e "${BOLD}${YELLOW}⚙️ STEP 4: Adding SSH key to agent...${RESET}\n"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo
echo -e "${GREEN}✅ SSH key added to agent successfully!${RESET}\n"

# 📋 STEP 5: Display public key
divider
echo -e "${BOLD}${CYAN}📋 STEP 5: Add this SSH key to GitHub${RESET}\n"
echo -e "${DIM}${YELLOW}--------------------------------------------------------------${RESET}"
cat ~/.ssh/id_ed25519.pub
echo -e "${DIM}${YELLOW}--------------------------------------------------------------${RESET}\n"
echo -e "${WHITE}➡️  Go to ${BLUE}https://github.com/settings/keys${RESET}"
echo -e "${WHITE}Click on 'New SSH key' → Paste the above key → Save.${RESET}\n"
read -p "Press [Enter] after adding your SSH key to GitHub..."

# 🧪 STEP 6: Test SSH connection
divider
echo -e "${BOLD}${YELLOW}🧪 STEP 6: Testing SSH connection to GitHub...${RESET}\n"
ssh -T git@github.com
echo -e "\n${GREEN}✅ SSH connection verified successfully!${RESET}\n"

# 💡 STEP 7: Ask if user wants upload helper
divider
echo -e "${BOLD}${YELLOW}💡 STEP 7: Optional Git Upload Helper${RESET}\n"
read -p "Wanna add the colorful 'upload' helper to .zshrc? (y/n): " choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
  echo -e "\n${CYAN}⚙️ Adding upload() function to ~/.zshrc...${RESET}\n"
  cat << 'EOF_UPLOAD_FUNCTION' >> ~/.zshrc

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
EOF_UPLOAD_FUNCTION
  echo -e "${GREEN}✅ Upload function added to .zshrc successfully!${RESET}\n"
else
  echo -e "\n${YELLOW}⚠️ Skipped adding upload() function.${RESET}\n"
fi

# 🏁 FINISH
divider
echo -e "${BOLD}${CYAN}"
echo "╔═══════════════════════════════════════════════╗"
echo "║   🎉 GIT + GITHUB SSH SETUP COMPLETED! 🎉     ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${RESET}"
