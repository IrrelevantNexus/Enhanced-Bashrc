#!/bin/bash

WORKINGDIR="$(cd "$(dirname -- "$0")" && pwd)"
RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
NC="\e[0m"

# Preview mode flag
PREVIEW_MODE=false

# Parse command line arguments
# Note: 'for arg in "$@"' iterates the original argument list, so no shift is needed here
for arg in "$@"; do
    case "$arg" in
        --preview|--dry-run)
            PREVIEW_MODE=true
            ;;
    esac
done

# Privilege policy shared by update() and .install.rc's fix functions:
# - If root: run directly (no sudo)
# - If non-root with usable sudo: run with sudo
# - If no elevation path: skip and continue (no manual sudo instructions)
# Return success if command can be executed with elevated privileges.
function can_elevate_privileges() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# Run a command as root when needed.
# Usage: run_with_privileges <command> [args...]
function run_with_privileges() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

function update() {
  if [ -n "$1" ]; then
    u=$1
  else
    read -p "Do you wish to check for a newer version from the GIT origin (y/n)? " u
  fi
  if [[ "${u,,}" == "y" ]] || [[ "${u,,}" == "yes" ]]; then
    echo "Attempting to run 'git pull'..."

    if ! command -v git > /dev/null 2>&1 ; then
      echo -e "${RED}Error: git is not installed. Please install git to enable updates.${NC}"
      return
    fi

    pushd "$WORKINGDIR" > /dev/null 2>&1

    if [ ! -d ".git" ]; then
      echo -e "${RED}Error: $WORKINGDIR is not a git repository. Updates are only available for git-based installations.${NC}"
    else
      echo "Configuring git repository..."
      # Only add safe.directory if it's not already configured (avoid duplicates on repeated updates)
      if ! git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$WORKINGDIR"; then
        git config --global --add safe.directory "$WORKINGDIR"
      fi
      
      echo "Checking for updates..."
      # Check for local changes
      local_changes=false
      if git status --porcelain | grep -q '^.M'; then
        echo -e "${YELLOW}Local changes detected. Stashing changes before update...${NC}"
        git stash push -m "Auto-stashed during update" > /dev/null 2>&1
        local_changes=true
      fi
      
      # Perform git pull. This works the same for any user as long as they can write to
      # $WORKINGDIR (their own clone, or a shared /opt/bashrc checkout they own). When a
      # non-owning user updates a shared /opt/bashrc checkout, fall back to sudo when
      # available instead of silently failing with a misleading network error.
      update_success=false
      permission_skip=false
      if [ -w "$WORKINGDIR" ]; then
        if git pull origin main; then
          update_success=true
        fi
      elif can_elevate_privileges; then
        if run_with_privileges git pull origin main; then
          update_success=true
        fi
      else
        permission_skip=true
        echo -e "${YELLOW}No write permission to $WORKINGDIR and no sudo access available. Skipping update.${NC}"
      fi
      
      # Inform user about stashed changes without reapplying them
      if [ "$local_changes" = true ]; then
        echo -e "${YELLOW}Note: Your local changes have been stashed but not reapplied.${NC}"
        echo -e "${YELLOW}You can view them with 'git stash list' and restore them if needed with 'git stash apply'.${NC}"
      fi
      
      if [ "$update_success" = true ]; then
        echo -e "${GREEN}Update completed successfully.${NC}"
        # Clear the update status file after successful update
        UPDATE_STATUS_FILE="/tmp/bashrc_update_status_$USER"
        if [ -f "$UPDATE_STATUS_FILE" ]; then
          rm -f "$UPDATE_STATUS_FILE"
          echo "no_update" > "$UPDATE_STATUS_FILE"
        fi
        # Also clear the update check timestamp to trigger a new check on next shell
        UPDATE_CHECK_FILE="$HOME/.config/bashrc/last_update_check"
        if [ -f "$UPDATE_CHECK_FILE" ]; then
          rm -f "$UPDATE_CHECK_FILE"
        fi
      elif [ "$permission_skip" = false ]; then
        echo -e "${RED}Update failed. Please check your network connection and git repository access.${NC}"
      fi
    fi
    popd > /dev/null 2>&1
  else
    echo "Skipping update check."
  fi
}

# Ensure /opt/bashrc exists by cloning if necessary, using dynamic upstream and branch.
# /opt/bashrc is only used to support the 'updatebash' alias; it is never required to install to $HOME,
# so a lack of write permission here should never block the rest of the install.
if [ ! -d "/opt/bashrc" ]; then
  if [ ! -w "/opt" ]; then
    echo -e "${YELLOW}Note: No write permission to /opt (root/sudo required). Skipping /opt/bashrc setup -${NC}"
    echo -e "${YELLOW}the 'updatebash' shortcut won't be available, but installation will continue normally.${NC}"
  else
    echo -e "${YELLOW}/opt/bashrc does not exist. Cloning Enhanced-Bashrc repository...${NC}"

    # Dynamically determine upstream repo and default branch
    UPSTREAM_URL="$(git -C "$WORKINGDIR" remote get-url origin 2>/dev/null)"
    DEFAULT_BRANCH="$(git -C "$WORKINGDIR" remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"
    if [ -z "$DEFAULT_BRANCH" ]; then
      DEFAULT_BRANCH="main"
    fi
    if [ -z "$UPSTREAM_URL" ]; then
      echo -e "${YELLOW}No upstream URL found for this repository. Skipping /opt/bashrc clone process.${NC}"
    else
      if [ "$PREVIEW_MODE" = false ]; then
        if ! command -v git > /dev/null 2>&1 ; then
          echo -e "${YELLOW}Warning: git is not installed. Skipping /opt/bashrc clone, continuing with installation.${NC}"
        elif git clone --depth=1 --branch "$DEFAULT_BRANCH" "$UPSTREAM_URL" /opt/bashrc; then
          echo -e "${GREEN}Repository cloned to /opt/bashrc successfully from $UPSTREAM_URL ($DEFAULT_BRANCH).${NC}"
        else
          echo -e "${YELLOW}Warning: Failed to clone repository to /opt/bashrc. Continuing with installation.${NC}"
        fi
      else
        echo -e "${YELLOW}[Preview] Would clone $UPSTREAM_URL ($DEFAULT_BRANCH) to /opt/bashrc${NC}"
      fi
    fi
  fi
fi

### Main Logic

if [ -n "$1" ]; then
  x=$1
fi

if [ "$PREVIEW_MODE" = true ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║          PREVIEW MODE - No changes will be made            ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
fi

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Enhanced Bash Configuration Installer v1.1.4           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This installer will configure your bash environment with:"
echo "  ✓ Smart git-aware prompt with virtualenv support"
echo "  ✓ Improved command history (1M commands, timestamps)"
echo "  ✓ Useful aliases for common tasks"
echo "  ✓ Safe file operation defaults"
echo "  ✓ Color support for ls, grep, and man pages"
echo ""
echo "Installation Details:"
echo "  User:          $USER"
echo "  Home:          $HOME"
echo "  Install from:  $WORKINGDIR"
echo "  Last updated:  $(stat -c "%y" "$WORKINGDIR/.bashrc" 2>/dev/null || echo "Unknown")"
echo "  Backup dir:    ~/.config/bashrc/backups/"
echo ""
if [ "$PREVIEW_MODE" = false ]; then
    echo "Tip: Run with --preview to see changes without installing"
    echo ""
fi

if [ ! -w "$HOME" ]; then
    echo -e "${RED}Error: No write permission in $HOME. Please check your permissions.${NC}"
    exit 1
fi

update "$@"
echo

if [ ! -f "$WORKINGDIR/.install.rc" ]; then
    echo -e "${RED}Error: Required file .install.rc not found in $WORKINGDIR"
    echo -e "Please ensure you have downloaded all required files.${NC}"
    exit 1
fi

source "$WORKINGDIR/.install.rc"
