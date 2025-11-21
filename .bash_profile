#!/bin/bash
## Bash enhancements provided by:
## - Mike Lilly
##

## ALLOWUPDATE allows you to choose if THIS FILE would be replaced with the newest version during bashrc updates.
## If you customize this file, please highly consider switching this variable to True.
## When updating, this existing file is copied as a back up to ~/.config/bashrc/ regardless of what this is set to.
ALLOWUPDATE='True'


### PROFILE

# Check for updates to the bashrc repository silently (only in interactive shells)
# This prevents interference with Ansible and other automation tools
# Only checks once per week to avoid slow network issues
if [[ $- == *i* ]]; then
  # Create config directory if it does not exist
  mkdir -p "$HOME/.config/bashrc" 2>/dev/null
  
  # Update check timestamp file
  UPDATE_CHECK_FILE="$HOME/.config/bashrc/last_update_check"
  UPDATE_STATUS_FILE="/tmp/bashrc_update_status_$USER"
  
  # Function to check if update check is needed (once per week)
  should_check_updates() {
    # If check file does not exist, we should check
    if [ ! -f "$UPDATE_CHECK_FILE" ]; then
      return 0
    fi
    
    # Get the last check timestamp
    local last_check=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local week_in_seconds=$((7 * 24 * 60 * 60))
    
    # Check if a week has passed
    if [ $((current_time - last_check)) -gt $week_in_seconds ]; then
      return 0
    fi
    
    return 1
  }
  
  # Only run update check if /opt/bashrc exists, is a git repo, and a week has passed
  if [ -d "/opt/bashrc" ] && [ -d "/opt/bashrc/.git" ] && should_check_updates; then
    # Run the update check in the background to avoid blocking the prompt
    (
      # Update the timestamp file first
      date +%s > "$UPDATE_CHECK_FILE" 2>/dev/null
      
      # Change to the bashrc directory
      cd "/opt/bashrc" || exit
      
      # Check for updates with a 120-second timeout to avoid hanging on slow networks
      # Use timeout command if available, otherwise use a simple background process with kill
      if timeout --version > /dev/null 2>&1; then
        # timeout command is available (most modern systems)
        if timeout 120 git remote update > /dev/null 2>&1; then
          UPSTREAM=${1:-'@{u}'}
          LOCAL=$(git rev-parse @ 2>/dev/null)
          REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null || echo "$LOCAL")
          
          if [ "$LOCAL" != "$REMOTE" ]; then
            echo "update_available" > "$UPDATE_STATUS_FILE"
          else
            echo "no_update" > "$UPDATE_STATUS_FILE"
          fi
        else
          # Timeout occurred or git command failed
          echo "check_failed" > "$UPDATE_STATUS_FILE"
        fi
      else
        # Fallback for systems without timeout command
        # Use a simple background process approach
        git remote update > /dev/null 2>&1 &
        local git_pid=$!
        local count=0
        while [ $count -lt 1200 ] && kill -0 $git_pid 2>/dev/null; do
          sleep 0.1
          count=$((count + 1))
        done
        
        if kill -0 $git_pid 2>/dev/null; then
          # Still running after 120 seconds, kill it
          kill -9 $git_pid 2>/dev/null
          echo "check_failed" > "$UPDATE_STATUS_FILE"
        else
          # Completed successfully
          wait $git_pid
          if [ $? -eq 0 ]; then
            UPSTREAM=${1:-'@{u}'}
            LOCAL=$(git rev-parse @ 2>/dev/null)
            REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null || echo "$LOCAL")
            
            if [ "$LOCAL" != "$REMOTE" ]; then
              echo "update_available" > "$UPDATE_STATUS_FILE"
            else
              echo "no_update" > "$UPDATE_STATUS_FILE"
            fi
          else
            echo "check_failed" > "$UPDATE_STATUS_FILE"
          fi
        fi
      fi
    ) &
    # Disown the background job so it does not show job control messages
    disown
  fi
fi

# set PATH so it includes users private bin if it exists
if [ -d "$HOME/bin" ] ; then
    if [[ ":$PATH:" != *"$HOME/bin"* ]]; then
        PATH="$HOME/bin:$PATH"
    fi
fi

# set PATH so it includes users private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    if [[ ":$PATH:" != *"$HOME/.local/bin"* ]]; then
        PATH="$HOME/.local/bin:$PATH"
    fi
fi

# set PATH so it includes the HDFView bin if it exists
if [ -d "/opt/hdfview/bin" ] ; then
    if [[ ":$PATH:" != *"/opt/hdfview/bin"* ]]; then
        PATH="/opt/hdfview/bin:$PATH"
    fi
fi

# set PATH so it includes PYENV if it exists
if [ -d "$HOME/.pyenv" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init - bash)"
fi

### DCONF

## dconf provides user customizations to GNOME Shell
## CUSTOMIZE - Add any additions or overrides for dconf to $HOME/.config/dconf.custom, instead of adding or editing them here directly
## Want to save your current gnome setup?
##  $ dconf dump / > $HOME/.config/dconf.custom

if [[ $XDG_CURRENT_DESKTOP == *"GNOME"* ]] && [[ -z "$TMUX" ]]; then 
  if [ -f /etc/dconf/dconf.global ]; then
    dconf load / < /etc/dconf/dconf.global > /dev/null 2>&1
  fi
  if [ -f "$HOME/.config/dconf.custom" ]; then
    dconf load / < "$HOME/.config/dconf.custom" > /dev/null 2>&1
    echo '' > "$HOME/.config/dconf.custom"
  fi
fi


### BASH

if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
