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

echo "✅ All done!"
