#!/bin/bash

# 🧩 FULL GIT + GITHUB SSH SETUP FOR TERMUX

# 1. Update and install git + openssh
pkg update -y && pkg upgrade -y
pkg install git openssh -y

# 2. Configure Git identity
read -p "Enter your Git user name: " git_user_name
git config --global user.name "$git_user_name"

read -p "Enter your Git user email: " git_user_email
git config --global user.email "$git_user_email"

# 3. Generate SSH key (use your GitHub email)
ssh-keygen -t ed25519 -C "$git_user_email" -f ~/.ssh/id_ed25519 -N ""

# 4. Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 5. Show your public key (copy this output)
echo "----- COPY THIS SSH KEY BELOW TO GITHUB -----"
cat ~/.ssh/id_ed25519.pub
echo "---------------------------------------------"
echo "Go to: https://github.com/settings/keys -> New SSH key -> Paste above key"
read -p "Press [Enter] key after you have added the SSH key to GitHub..."

# 6. (After adding SSH key to GitHub) test connection:
echo "Testing GitHub SSH connection..."
ssh -T git@github.com

echo "✅ Git setup done!"

# 7. Add the upload function to .zshrc
echo '
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
    if ! git commit -m "$MSG"; then
      echo -e "${RED}❌ Commit failed.${RESET}"
      return 1
    fi
    echo -e "${GREEN}✅ Committed: ${MSG}${RESET}"
  fi

  # Push to current branch
  if git remote | grep -q "^origin$"; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$BRANCH" = "HEAD" ]; then
      echo -e "${YELLOW}⚠️  Detached HEAD; cannot determine branch to push.${RESET}"
      return 1
    fi
    if git push origin "$BRANCH"; then
      echo -e "${GREEN}🚀 Pushed successfully to branch \'${BRANCH}\ நேரடியாக!${RESET}"
    else
      echo -e "${RED}❌ Push failed.${RESET}"
    fi
  else
    echo -e "${YELLOW}⚠️  Remote \'origin\' not found; push skipped.${RESET}"
  fi
}
' >> ~/.zshrc

echo "✅ Upload function added to .zshrc"
