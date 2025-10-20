#!/bin/bash
# post-setup.sh - Interactive script to tweak Starship prompt after initial setup
CFG="$HOME/.config/starship.toml"

if [ ! -f "$CFG" ]; then
    echo "❌ starship.toml not found at $CFG"
    exit 1
fi

echo "🚀 Post-setup configuration for Starship prompt"

# Helper function to add or edit a key inside a section
set_or_add_key() {
    local section="$1"
    local key="$2"
    local value="$3"

    if grep -q "^\[$section\]" "$CFG"; then
        # Section exists, replace or add key
        if grep -q "^\s*$key\s*=" "$CFG"; then
            sed -i "/^\[$section\]/,/^\[/{s/^\s*$key\s*=.*/$key = $value/}" "$CFG"
        else
            sed -i "/^\[$section\]/a $key = $value" "$CFG"
        fi
    else
        # Section doesn't exist, append it
        echo -e "\n[$section]\n$key = $value" >> "$CFG"
    fi
}

# 1. Ask about 12-hour time format
read -rp "Do you want 12-hour AM/PM time format? (y/N): " use_12h
if [[ "$use_12h" =~ ^[Yy]$ ]]; then
    set_or_add_key "time" "time_format" "\"%I:%M %p\""
    set_or_add_key "time" "disabled" "false"
    echo "✅ 12-hour time format applied."
else
    echo "⏰ Keeping current time format."
fi

# 2. Ask about command_timeout value
read -rp "Enter command_timeout value (default 100): " cmd_timeout
cmd_timeout="${cmd_timeout:-100}"

# Check if command_timeout already exists
if grep -q '^command_timeout' "$CFG"; then
    sed -i "s/^command_timeout.*/command_timeout = $cmd_timeout/" "$CFG"
else
    # Insert after first line
    sed -i "1a command_timeout = $cmd_timeout" "$CFG"
fi

echo "⏱ command_timeout set to $cmd_timeout."

# 3. Ask about two-liner prompt
read -rp "Do you want a two-liner prompt? (y/N): " two_liner
if [[ "$two_liner" =~ ^[Yy]$ ]]; then
    set_or_add_key "line_break" "disabled" "false"
    echo "✅ Two-liner prompt enabled."
else
    set_or_add_key "line_break" "disabled" "true"
    echo "➡ Two-liner prompt disabled."
fi

# 4. Ask about showing command duration
read -rp "Do you want to show command duration? (y/N): " show_duration
if [[ "$show_duration" =~ ^[Yy]$ ]]; then
    set_or_add_key "cmd_duration" "disabled" "false"
    echo "✅ Command duration enabled."
else
    set_or_add_key "cmd_duration" "disabled" "true"
    echo "➡ Command duration disabled."
fi

echo "🎉 Post-setup configuration complete!"
