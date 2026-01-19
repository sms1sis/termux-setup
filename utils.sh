#!/bin/bash
# utils.sh - Shared utilities for Termux Setup Scripts

# --- Configuration ---
# Scripts sourcing this should set LOGFILE before sourcing, 
# or it defaults to a generic one.
: "${LOGFILE:=$HOME/termux_setup_generic.log}"

# --- Color Definitions ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'
C_UNDERLINE='\033[4m'

# --- Logging Functions ---
log()        { echo -e "${C_GREEN}[✔]${C_RESET} $1" | tee -a "$LOGFILE"; }
warn()       { echo -e "${C_YELLOW}[!]${C_RESET} $1" | tee -a "$LOGFILE"; }
error_exit() { echo -e "${C_RED}[✖]${C_RESET} $1" | tee -a "$LOGFILE"; exit 1; }
info()       { echo -e "${C_CYAN}[i]${C_RESET} $1" | tee -a "$LOGFILE"; }
section()    { echo -e "\n${C_MAGENTA}✨ ${C_BOLD}$1${C_RESET}\n"; }

# --- Helper Functions ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " ${C_CYAN}%c${C_RESET}  " "$spinstr"
        local spinstr=$temp${spinstr%???}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

typewriter() {
    local text="$(echo -e "$1")"
    local delay=${2:-0.03}
    local n=${#text}
    local i=0
    while [ $i -lt $n ]; do
        local char="${text:$i:1}"
        if [[ "$char" == $'\e' ]]; then
            printf "%s" "$char"
            i=$((i+1))
            while [ $i -lt $n ]; do
                local next_char="${text:$i:1}"
                printf "%s" "$next_char"
                i=$((i+1))
                if [[ "$next_char" =~ [a-zA-Z] ]]; then
                    break
                fi
            done
        else
            printf "%s" "$char"
            sleep "$delay"
            i=$((i+1))
        fi
    done
    echo ""
}

draw_box() {
    local title="$1"
    shift
    local lines=("$@")
    local longest=0
    
    # Calculate width
    for line in "${lines[@]}"; do
        # Strip ANSI codes for length calculation
        clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        len=${#clean_line}
        if [ "$len" -gt "$longest" ]; then
            longest=$len
        fi
    done

    # Add padding
    width=$((longest + 4))
    
    # Top border
    printf "${C_BLUE}╔"
    for ((i=0; i<width; i++)); do printf "═"; done
    printf "╗${C_RESET}\n"
    
    # Title (centered if possible, or just printed)
    if [ -n "$title" ]; then
        clean_title=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        title_len=${#clean_title}
        pad=$(( (width - title_len) / 2 ))
        printf "${C_BLUE}║${C_RESET}"
        for ((i=0; i<pad; i++)); do printf " "; done
        printf "${C_BOLD}${C_MAGENTA}%s${C_RESET}" "$title"
        pad_right=$(( width - title_len - pad ))
        for ((i=0; i<pad_right; i++)); do printf " "; done
        printf "${C_BLUE}║${C_RESET}\n"
        
        # Separator
        printf "${C_BLUE}╠"
        for ((i=0; i<width; i++)); do printf "═"; done
        printf "╣${C_RESET}\n"
    fi

    # Content
    for line in "${lines[@]}"; do
        clean_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        len=${#clean_line}
        pad=$(( width - len - 2 )) # -2 for left padding
        printf "${C_BLUE}║${C_RESET} %b" "$line"
        for ((i=0; i<pad; i++)); do printf " "; done
        printf " ${C_BLUE}║${C_RESET}\n"
    done

    # Bottom border
    printf "${C_BLUE}╚"
    for ((i=0; i<width; i++)); do printf "═"; done
    printf "╝${C_RESET}\n"
}

execute() {
    local cmd=$1
    local msg=$2
    local use_sudo=${3:-false} # Optional 3rd arg to force/disable sudo logic if needed
    
    info "$msg"

    # Handle sudo if SUDO variable is set in the environment (for proot script)
    if [ -n "${SUDO:-}" ]; then
        # For apt commands in proot, ensure non-interactive
        if [[ "$cmd" == *"apt install"* || "$cmd" == *"apt update"* || "$cmd" == *"apt upgrade"* ]]; then
             cmd="DEBIAN_FRONTEND=noninteractive $SUDO $cmd"
        else
             cmd="$SUDO $cmd"
        fi
    fi

    # Run command
    sh -c "$cmd" &> "$LOGFILE" &
    spinner $!
    wait $!
    
    if [ $? -eq 0 ]; then
        log "$msg - Done"
    else
        # We don't always exit on failure in execute, 
        # but the original scripts sometimes used error_exit.
        # However, execute() in setup.sh used error_exit, while proot used error_exit.
        # Let's standardize on error_exit for critical failures if they happen here?
        # Actually, looking at source:
        # setup.sh: execute() calls error_exit on fail.
        # proot: execute() calls error_exit on fail.
        # So we can safely use error_exit.
        error_exit "$msg - Failed (Check $LOGFILE for details)"
    fi
}

backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%s)"
        info "Backed up $file"
    fi
}

check_internet() {
    info "Checking internet connection..."
    if curl -s --head  --request GET google.com | grep "200 OK" > /dev/null; then 
        log "Internet connected."
    else
        warn "Internet may be disconnected."
    fi
}

self_update() {
    section "Self-Update"
    local repo_dir
    repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    
    if [ ! -d "$repo_dir/.git" ]; then
        warn "Not a git repository. Cannot auto-update."
        return
    fi

    info "Checking for updates..."
    # navigate to repo dir
    pushd "$repo_dir" >/dev/null
    
    if git fetch origin main; then
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            info "Update available! Installing..."
            if git pull origin main; then
                 log "Update complete. Please restart the script."
                 popd >/dev/null
                 exit 0
            else
                 error_exit "Update failed."
            fi
        else
            log "Script is already up to date."
        fi
    else
        warn "Failed to check for updates (git fetch failed)."
    fi
    popd >/dev/null
}
