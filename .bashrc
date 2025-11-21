#!/bin/bash
## Enhanced Bash Configuration
## Author: Mike Lilly
##
## This is the main configuration file that sets up the enhanced bash environment.
## It handles updates, customization, and core functionality.

## Version information
export BASHRC_VERSION="1.1.7"
export BASHRC_LAST_UPDATE="2025-11-18"

### UPDATING

### Updating This Bashrc
## The goal is to avoid forcing updates. If you choose to update, ~/.bashrc-custom will not be changed by default.
## The rest of the files however are set to update when auto updates are rolled out and when you choose to update manually.
alias updatebash='/opt/bashrc/INSTALL.sh y'
alias updatebash-preview='/opt/bashrc/INSTALL.sh --preview'

## Force an immediate update check (ignores the weekly timer)
alias updatebash-check='rm -f ~/.config/bashrc/last_update_check && source ~/.bash_profile && echo "Update check triggered. Check status with: bashrc-update-status"'

## Show when the last update check occurred
alias bashrc-update-status='if [ -f ~/.config/bashrc/last_update_check ]; then echo "Last update check: $(date -d @$(cat ~/.config/bashrc/last_update_check) 2>/dev/null || echo "Unknown")"; else echo "No update check performed yet"; fi; if [ -f /tmp/bashrc_update_status_$USER ]; then status=$(cat /tmp/bashrc_update_status_$USER); case "$status" in update_available) echo "Status: Update available - run updatebash to install";; no_update) echo "Status: Up to date";; check_failed) echo "Status: Last check failed (network issue?)";; *) echo "Status: Unknown";; esac; else echo "Status: No check results available"; fi'

## ALLOWUPDATE allows you to choose if THIS FILE would be replaced with the newest version during bashrc updates.
## If you customize this file, please highly consider switching this variable to False.
## When updating, this existing file is copied as a back up to ~/.config/bashrc/ regardless of what this is set to.
ALLOWUPDATE='True'


## Set this to True if you want the latest version when we sparingly find it appropriate to roll out changes.
## Consider using ALLOWUPDATE before changing this value.
AutoUpdateBash='True'

## If you prefer doing things your own way, no worries. Feel free to configure the contents of ~/.config/bashrc/, this file, as well as .bash_profile as you please.
## If you are the type of person to do so, I'd love to see what you have! -MLilly
## If you have suggestions feel free to submit feedback on the Issues board in the GitLab Repo, or reach out on Teams!


### GENERAL

## Enable the subsequent settings only in interactive sessions
[[ $- != *i* ]] && return

## CUSTOMIZE - If you enable AutoUpdateBash, or plan to install updates manually -
##   DON'T MODIFY THIS FILE! To persist through updates, keep customizations to ~/.bashrc-custom" or change ALLOWUPDATE!
##   Want to change the PS1 prompt? .bashrc-custom has an include for /.config/bashrc/prompt.rc
if [ -f "$HOME/.bashrc-custom" ]; then
  . "$HOME/.bashrc-custom"
  # Set initial prompt if in interactive shell and prompt function exists
  if [[ $- == *i* ]] && type set_bash_prompt &>/dev/null; then
    set_bash_prompt
  fi
fi

# Help prevent Kerberos tickets from expiring (only in interactive shells)
# Run in background to avoid startup delays
if [[ $- == *i* ]]; then
  (kinit -R > /dev/null 2>&1 &) > /dev/null
fi

# Yay colors!
TXTCOLOR=$(tput setaf 6) # Cyan
TXTALRT=$(tput setaf 1) # Red
TXTWHT=$(tput setaf 7)  # White

### BROWSER DIRECTORIES
## Create hostname-specific browser directories if they don't exist
## This supports the Ansible configuration that uses hostname-specific browser profiles

function create_browser_directories() {
    # Create Chrome directory with hostname
    local chrome_dir="$HOME/.config/google-chrome/$HOSTNAME"
    if [[ ! -d "$chrome_dir" ]]; then
        mkdir -p "$chrome_dir" 2>/dev/null || handle_error "Failed to create Chrome directory: $chrome_dir"
    fi
    
    # Create Firefox directory with hostname
    local firefox_dir="$HOME/.mozilla/firefox/$HOSTNAME"
    if [[ ! -d "$firefox_dir" ]]; then
        mkdir -p "$firefox_dir" 2>/dev/null || handle_error "Failed to create Firefox directory: $firefox_dir"
    fi
}

# Create browser directories on shell initialization
create_browser_directories

### CORE FUNCTIONS
## Each function is designed to be self-contained and handle errors gracefully

## handle_error: Standardized error handling with color output
function handle_error() {
    local exit_code=$?
    printf "${TXTALRT}Error: %s${TXTWHT}\n" "$1"
    return $exit_code
}

# SELinux Autorelabel - Generally we create this file when system updates are applied. On reboot, if /.autorelabel exists, the system will relabel files on the system and then reboot again.
function set_autorelabel () {
  if [[ -f "/.autorelabel" ]]; then
    printf "${TXTALRT}Autorelabel is set to run on next boot. System Reboot for $HOSTNAME may be required. Please reboot when convenient. Note: Autorelabel may take some time to complete.${TXTWHT}\n\n"
  fi
}

# /etc/motd is used to broadcast messages, if we choose so.
function set_MOTD () {
  # Check if update is available
  UPDATE_STATUS_FILE="/tmp/bashrc_update_status_$USER"
  if [ -f "$UPDATE_STATUS_FILE" ]; then
    local status=$(cat "$UPDATE_STATUS_FILE")
    case "$status" in
      update_available)
        # Verify the status is still accurate before displaying banner
        if [ -d "/opt/bashrc/.git" ]; then
          local LOCAL=$(cd /opt/bashrc && git rev-parse @ 2>/dev/null)
          local REMOTE=$(cd /opt/bashrc && git rev-parse @{u} 2>/dev/null)
          if [ -n "$LOCAL" ] && [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
            # Update is truly available
            printf "${TXTCOLOR}Bash Configuration Update:${TXTWHT} An update is available. Run ${TXTCOLOR}updatebash${TXTWHT} to install.\n\n"
          else
            # Status is stale, clear it
            echo "no_update" > "$UPDATE_STATUS_FILE" 2>/dev/null
          fi
        fi
        ;;
      check_failed)
        # Don't show anything for failed checks to avoid clutter
        # Users can run bashrc-update-status to see details
        ;;
      no_update)
        # Don't show anything when up to date
        ;;
    esac
  fi

  # Display regular MOTD
  if [[ -s /etc/motd ]]; then
    printf "${TXTCOLOR}Message of the Day:${TXTWHT}\n"
    cat '/etc/motd'
    printf "\n"
  fi
}

# /opt/motd allows anyone to bradcast messages on this workstation. Enjoy.
function set_WKSTMOTD () {
  if [[ -s /opt/motd ]]; then
    printf "${TXTCOLOR}Local messages from /opt/motd:${TXTWHT}\n"
    cat '/opt/motd'
    printf "\n"
  fi
}

## Show version information
function bashrc-version() {
    echo "Enhanced Bash Configuration"
    echo "Version: $BASHRC_VERSION"
    echo "Last Update: $BASHRC_LAST_UPDATE"
    echo "Location: $(readlink -f ~/.bashrc 2>/dev/null || echo ~/.bashrc)"
    echo ""
    
    # Check if update available by comparing git commits
    if [ -d "/opt/bashrc/.git" ]; then
        local LOCAL=$(cd /opt/bashrc && git rev-parse @ 2>/dev/null)
        local REMOTE=$(cd /opt/bashrc && git rev-parse @{u} 2>/dev/null)
        
        if [ -n "$LOCAL" ] && [ -n "$REMOTE" ]; then
            if [ "$LOCAL" != "$REMOTE" ]; then
                local REPO_VERSION=$(grep "^export BASHRC_VERSION=" /opt/bashrc/.bashrc 2>/dev/null | cut -d'"' -f2)
                echo -e "${YELLOW}Update available: ${REPO_VERSION:-unknown version}${TXTWHT}"
                echo "Run 'updatebash' to install the latest version"
            else
                echo -e "${GREEN}You are up to date!${TXTWHT}"
            fi
        else
            echo "Unable to check for updates (git repository issue)"
        fi
    elif [ -f "/opt/bashrc/.bashrc" ]; then
        # Fallback to version comparison if not a git repo
        local REPO_VERSION=$(grep "^export BASHRC_VERSION=" /opt/bashrc/.bashrc 2>/dev/null | cut -d'"' -f2)
        if [ -n "$REPO_VERSION" ] && [ "$REPO_VERSION" != "$BASHRC_VERSION" ]; then
            echo -e "${YELLOW}Update available: $REPO_VERSION${TXTWHT}"
            echo "Run 'updatebash' to install the latest version"
        else
            echo -e "${GREEN}You are up to date!${TXTWHT}"
        fi
    else
        echo "Unable to check for updates (/opt/bashrc not found)"
    fi
}

### MAIN - Only run in interactive shells to avoid interfering with Ansible/automation
if [[ $- == *i* ]]; then
  set_autorelabel
  echo -e "${TXTCOLOR}""System: ""${TXTWHT}""$HOSTNAME"
  echo -e "${TXTCOLOR}""Uptime: ""${TXTWHT}"$(uptime | sed 's/.*up \(.*\),.*user.*/\1/')
  echo -e "${TXTCOLOR}""   CPU: ""${TXTWHT}"$(lscpu | grep 'CPU(s):' | head -n1 | awk '{print $2 " threads"}')
  echo -e "${TXTCOLOR}""Memory: ""${TXTWHT}"$(free -b | awk 'NR==2{printf "%.2fGi/%.2fGi (%.2f%%)\n", $3/(1024^3), $2/(1024^3), $3/$2*100}')
  echo -e "${TXTCOLOR}"" Users: ""${TXTWHT}"$(who | awk '!seen[$1]++ {printf $1 " "}')
  echo;
  set_MOTD
  set_WKSTMOTD
fi
