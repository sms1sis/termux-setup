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
section()    { echo -e "\n\033[1;36m━━━ \033[1;95m${C_BOLD}$1\033[0m\033[1;36m ━━━\033[0m\n"; }

# --- Helper Functions ---
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    printf "\e[?25l" # Hide cursor
    while kill -0 "$pid" 2>/dev/null; do
        local temp="${spinstr#?}"
        printf " ${C_CYAN}%s${C_RESET}  " "${spinstr:0:1}"
        spinstr="${temp}${spinstr%"$temp"}"
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
    printf "\e[?25h" # Show cursor
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
    local -a clean_lines

    # Batch process ANSI stripping for all lines to avoid subshell overhead per line.
    # We use printf "%b\n" to interpret escapes (like echo -e) before stripping.
    if [ ${#lines[@]} -gt 0 ]; then
        mapfile -t clean_lines < <(printf "%b\n" "${lines[@]}" | sed 's/\x1b\[[0-9;]*m//g')
    fi

    # Calculate width
    for clean_line in "${clean_lines[@]}"; do
        len=${#clean_line}
        if [ "$len" -gt "$longest" ]; then
            longest=$len
        fi
    done

    # Add padding
    width=$((longest + 4))
    
    # Top border (Rounded)
    printf "${C_BLUE}╭"
    for ((i=0; i<width; i++)); do printf "─"; done
    printf "╮${C_RESET}\n"
    
    # Title (centered if possible, or just printed)
    if [ -n "$title" ]; then
        clean_title=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        title_len=${#clean_title}
        pad=$(( (width - title_len) / 2 ))
        printf "${C_BLUE}│${C_RESET}"
        for ((i=0; i<pad; i++)); do printf " "; done
        printf "${C_BOLD}${C_MAGENTA}%s${C_RESET}" "$title"
        pad_right=$(( width - title_len - pad ))
        for ((i=0; i<pad_right; i++)); do printf " "; done
        printf "${C_BLUE}│${C_RESET}\n"
        
        # Separator
        printf "${C_BLUE}├"
        for ((i=0; i<width; i++)); do printf "─"; done
        printf "┤${C_RESET}\n"
    fi

    # Content
    for i in "${!lines[@]}"; do
        line="${lines[$i]}"
        clean_line="${clean_lines[$i]}"
        len=${#clean_line}
        pad=$(( width - len - 2 )) # -2 for left padding
        printf "${C_BLUE}│${C_RESET} %b" "$line"
        for ((j=0; j<pad; j++)); do printf " "; done
        printf " ${C_BLUE}│${C_RESET}\n"
    done

    # Bottom border (Rounded)
    printf "${C_BLUE}╰"
    for ((i=0; i<width; i++)); do printf "─"; done
    printf "╯${C_RESET}\n"
}

execute() {
    local cmd=$1
    local msg=$2
    local use_sudo=${3:-false} # Optional 3rd arg to force/disable sudo logic if needed
    
    info "$msg"

    # For apt/apt-get/pkg commands, ensure non-interactive
    if [[ "$cmd" == *"apt "* || "$cmd" == *"apt-get "* || "$cmd" == *"pkg "* ]]; then
         cmd="DEBIAN_FRONTEND=noninteractive $cmd"
    fi

    # Handle sudo if SUDO variable is set in the environment (for proot script)
    if [ -n "${SUDO:-}" ]; then
         cmd="$SUDO $cmd"
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
    # Use exit-status checks (curl -f) against lightweight, redirect-free
    # endpoints instead of grepping status text: modern curl defaults to
    # HTTP/2, whose status line is "HTTP/2 200" (no "200 OK" string), and
    # bare "google.com" without -L/https can redirect before ever reaching
    # a 200 — both of which produced false "disconnected" warnings even
    # with a working connection.
    if curl -fsS --max-time 5 -o /dev/null "https://www.google.com/generate_204" \
        || curl -fsS --max-time 5 -o /dev/null "https://1.1.1.1"; then
        log "Internet connected."
        return 0
    else
        warn "Internet may be disconnected."
        return 1
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
    
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    if git fetch origin "$BRANCH"; then
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse "origin/$BRANCH")
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            info "Update available! Installing..."
            if git pull origin "$BRANCH"; then
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
