`markdown

📱 Termux Unified Setup Script

A single modular script to automate and customize your Termux environment — from base packages to Zsh + Starship, GitHub integration, and post‑setup tweaks.

---

🖥️ Output Preview
`
[*] Running base setup...
[*] Installing git...
[*] Installing zsh...
[*] Configuring Starship + Zsh
[*] Setup complete! Restart Termux or run 'zsh'
`

---

✨ Features

- Base Setup
  - Updates & upgrades Termux
  - Installs essential packages: git, curl, wget, zsh

- Shell & Prompt
  - Installs Zsh
  - Installs the blazing‑fast Starship prompt
  - Auto‑configures .zshrc with Starship

- Post Setup
  - Interactive choice of Starship presets (catppuccin-powerline, tokyo-night, gruvbox-rainbow)
  - Backs up existing configs before overwriting

- Git & GitHub
  - Configure Git username & email
  - Generate SSH key (if not already present)
  - Add key to SSH agent
  - Prints public key for GitHub setup

- Automation Friendly
  - Unified script with subcommands: base, starship, git, post, all
  - Safe shell switching (--switch for next login, --switch-now for immediate)

- Safety
  - Automatic backups of configs (.zshrc, starship.toml)
  - Logging to termux_setup.log

---

🚀 Quick Start

`bash
pkg update -y && pkg install git -y
git clone https://github.com/sms1sis/termux-setup.git
cd termux-setup
chmod +x setup.sh
`

---

⚡ Usage

- Full setup (recommended):
  `bash
  ./setup.sh all --switch
  `
  Installs everything and sets Zsh as default for next login.

- Base only:
  `bash
  ./setup.sh base
  `

- Starship + Zsh config:
  `bash
  ./setup.sh starship
  `

- Git + GitHub setup:
  `bash
  ./setup.sh git
  `

- Post‑setup (Starship presets):
  `bash
  ./setup.sh post
  `

- Switch shell immediately (interactive only):
  `bash
  ./setup.sh all --switch-now
  `

---

⚙️ Optional Steps

- Customize Starship
  - Presets applied via ./setup.sh post
  - Edit manually at ~/.config/starship.toml
  - More themes: Starship Presets

- Check Logs
  - All actions are logged to termux_setup.log

---

🛠️ Troubleshooting

- If chsh is not available, the script falls back to adding exec zsh in .bashrc.
- If SSH key generation fails, check permissions on ~/.ssh and rerun ./setup.sh git.
- For Starship issues, run starship doctor to diagnose.

---

🙌 Credits

- Starship — minimal, blazing‑fast, infinitely customizable prompt  
- Termux — the Android terminal emulator that makes this possible  

---

💡 This script is modular. Run only what you need, or all for the full experience.
`
