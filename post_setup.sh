#!/bin/bash
# post-setup.sh - Interactive script to tweak Starship prompt after initial setup

# --- Color Definitions ---
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

CFG="$HOME/.config/starship.toml"

if [ ! -f "$CFG" ]; then
    echo -e "${RED}❌ starship.toml not found at $CFG${NC}"
    exit 1
fi

echo -e "\n${BOLD}${CYAN}🚀 Post-setup configuration for Starship prompt${NC}\n"

# Helper function to edit a key *only* if the section exists
edit_key_in_section() {
    local section="$1"
    local key="$2"
    local value="$3"
    local section_header="\[$section\]" # Escaped for grep/sed
    local key_pattern="^\s*$key\s*="

    # 1. Check if section exists
    if ! grep -q "^$section_header" "$CFG"; then
        # Section doesn't exist. Print warning and exit function.
        echo -e "  ${YELLOW}⚠️ Warning: Section [$section] not found. Skipping...${NC}"
        return 1
    fi

    # 2. Section exists. Check if key exists within it.
    if sed -n "/^$section_header/,/^\[/{ /$key_pattern/p }" "$CFG" | grep -q .; then
        # Key exists, replace it
        sed -i "/^$section_header/,/^\[/{s/$key_pattern.*/$key = $value/}" "$CFG"
    else
        # Key doesn't exist, add it after the section header
        sed -i "/^$section_header/a $key = $value" "$CFG"
    fi
    return 0 # Return success
}

# 1. Ask about command_timeout value
read -rp "$(echo -e "${YELLOW}❓ Enter command_timeout value (default 100): ${NC}")" cmd_timeout
cmd_timeout="${cmd_timeout:-100}"

# Check if command_timeout already exists (as a global key)
if grep -q "^command_timeout\s*=" "$CFG"; then
    # It exists, so replace it
    sed -i "s/^command_timeout\s*=.*/command_timeout = $cmd_timeout/" "$CFG"
else
    # It doesn't exist, so add it as the first line
    sed -i "1i command_timeout = $cmd_timeout" "$CFG"
fi
echo -e "  ${GREEN}⏱ command_timeout set to $cmd_timeout.${NC}"

# 2. Ask about 12-hour time format
read -rp "$(echo -e "${YELLOW}❓ Do you want 12-hour AM/PM time format? (y/N): ${NC}")" use_12h
if [[ "$use_12h" =~ ^[Yy]$ ]]; then
    # Attempt to set 12-hour format
    if edit_key_in_section "time" "time_format" "\"%I:%M %p\""; then
        edit_key_in_section "time" "disabled" "false" # Also enable
        echo -e "  ${GREEN}✅ 12-hour time format applied.${NC}"
    fi
else
    # Attempt to set 24-hour format
    if edit_key_in_section "time" "time_format" "\"%R\""; then
        edit_key_in_section "time" "disabled" "false" # Also enable
        echo -e "  ${BLUE}⏰ 24-hour time format applied.${NC}"
    fi
fi

# 3. Ask about two-liner prompt
read -rp "$(echo -e "${YELLOW}❓ Do you want a two-liner prompt? (y/N): ${NC}")" two_liner
if [[ "$two_liner" =~ ^[Yy]$ ]]; then
    if edit_key_in_section "line_break" "disabled" "false"; then
        echo -e "  ${GREEN}✅ Two-liner prompt enabled.${NC}"
    fi
else
    if edit_key_in_section "line_break" "disabled" "true"; then
        echo -e "  ${BLUE}➡ Two-liner prompt disabled.${NC}"
    fi
fi

# 4. Ask about showing command duration
read -rp "$(echo -e "${YELLOW}❓ Do you want to show command duration? (y/N): ${NC}")" show_duration
if [[ "$show_duration" =~ ^[Yy]$ ]]; then
    if edit_key_in_section "cmd_duration" "disabled" "false"; then
        echo -e "  ${GREEN}✅ Command duration enabled.${NC}"
    fi
else
    if edit_key_in_section "cmd_duration" "disabled" "true"; then
        echo -e "  ${BLUE}➡ Command duration disabled.${NC}"
    fi
fi

echo -e "\n${BOLD}${GREEN}🎉 Post-setup configuration complete!${NC}\n"
