# Enhanced Bash Configuration

A comprehensive bash configuration system with smart prompts, useful aliases, and sane defaults.

## Quick Start

### First-Time Installation

1. **Clone or download this repository**
   ```bash
   cd /opt
   git clone <repo-url> bashrc
   cd bashrc
   ```

2. **Preview what will be installed** (optional but recommended)
   ```bash
   ./INSTALL.sh --preview
   ```

3. **Run the installer**
   ```bash
   ./INSTALL.sh
   ```

4. **Restart your terminal** or source the new configuration
   ```bash
   source ~/.bashrc
   ```

5. **Verify installation**
   ```bash
   bashrc-version
   bashrc-help
   ```

### After Installation

- **Get help**: Run `bashrc-help` to see available commands
- **List aliases**: Run `list-aliases` to see all shortcuts  
- **List functions**: Run `list-functions` to see custom functions
- **Customize**: Edit `~/.bashrc-custom` for your own settings
- **Update**: Run `updatebash` when updates are available

### Common First Steps

```bash
# See what's available
bashrc-help

# List all aliases
list-aliases

# Check your version
bashrc-version

# Customize your setup
vim ~/.bashrc-custom
```

## Features

### Smart Command Line
- Intelligent prompt with git status, virtualenv, and conda environment
- Automatic terminal title updates with current context
- History search with up/down arrows
- Smart command completion with case insensitivity
- Color support for ls, grep, and man pages

### Python Development
- Automatic pyenv integration
- Python 3 as default with sane configurations
- Virtual environment status in prompt
- Conda environment support
- PIP safety defaults

### Development Tools
- Git-aware prompt showing branch and status
- Useful aliases for common operations
- Extract function for various archive formats
- Safe file operation defaults
- Network and process management tools

### GNOME Integration
- Optimized desktop settings for RHEL 8/9
- Dark theme configuration
- Custom keyboard shortcuts
- Improved file manager settings

## Installation

```bash
./INSTALL.sh
```

The installer provides:
1. Automatic backup of existing configurations
2. Safe installation with permission checks
3. Optional git-based updates
4. Cleanup of old backup files
5. Clear error reporting and status updates

## Customization

### Core Configuration
- Edit `.bashrc-custom` for personal customizations
- Set `ALLOWUPDATE='False'` in files you modify to prevent updates
- Add local GNOME settings to `.config/dconf.custom`

### Terminal Behavior
- History settings in `settings.rc`
- Command completion options
- Color schemes and terminal appearance
- Optional real-time history sync across terminals

### Python Environment
- Configure pyenv in `.bashrc-custom`
- Customize Python environment variables
- Add project-specific virtual environments

## File Structure

- `.bashrc` - Main configuration loader
- `.bash_profile` - Login shell configuration 
- `.config/bashrc/`
  - `settings.rc` - Core bash settings and history
  - `prompt.rc` - Smart prompt with git/venv support
  - `bash_aliases.rc` - Useful command aliases

## Backup Management

- Backups stored in `~/.config/bashrc/backups`
- Dated backup files for easy restore
- Automatic cleanup of backups older than 90 days (optional)
- Safe backup strategy before any updates

## Updates

To update your configuration:
```bash
updatebash
```

The update process:
1. Checks for git repository access
2. Creates backups of existing files
3. Updates only allowed files (respects ALLOWUPDATE)
4. Preserves all local customizations
5. Reports success or failure clearly

### Automatic Update Notifications

The system silently checks for updates when you log in:
- Checks run **in the background** and won't block your terminal from loading
- Checks only happen **once per week** to avoid slow network issues
- If updates are available in `/opt/bashrc`, a notification will appear in your MOTD
- Run `updatebash` to install the updates when notified
- No notification appears when your system is up-to-date
- All checks happen in the background without interrupting your workflow

#### Update Check Commands

| Command | Description |
|---------|-------------|
| `updatebash-check` | Force an immediate update check (ignores weekly timer) |
| `bashrc-update-status` | Show when last check occurred and current status |
| `updatebash` | Install available updates |
| `updatebash-preview` | Preview what will change before updating |

#### How Update Checks Work

1. **Weekly Timer**: Checks only run if 7+ days have passed since the last check
2. **Background Execution**: Git operations run in background to avoid blocking your prompt
3. **120-Second Timeout**: Git fetch operations timeout after 120 seconds to prevent hanging on slow networks
4. **Smart Detection**: Only runs if `/opt/bashrc` exists and is a git repository
5. **Status Tracking**: Results stored in `/tmp/bashrc_update_status_$USER`
6. **Timestamp File**: Last check time saved in `~/.config/bashrc/last_update_check`

This design prevents slow network connections (like GitLab) from delaying your terminal startup. If the network is too slow and the check times out, it will be marked as failed and won't show any notification.

## Troubleshooting

### Quick Fixes

**Prompt looks weird?**
- Your terminal may not support all features
- Try: `export TERM=xterm-256color`
- Or use a different terminal emulator (GNOME Terminal recommended)

**Git status not showing?**
- Make sure you're in a git repository: `git status`
- Check git is installed: `git --version`

**Commands not found after installation?**
- Restart your terminal or run: `source ~/.bashrc`
- Verify installation: `bashrc-version`

**Want to undo changes?**
- Run `restorebash --list` to see backups
- Run `restorebash --latest` to restore previous configuration

### Getting Help

1. **Check the help system**: `bashrc-help`
2. **See full troubleshooting guide**: `TROUBLESHOOTING.md`
3. **List backups**: `restorebash --list`
4. **Check version**: `bashrc-version`

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## New Commands Reference

After installation, these commands are available:

| Command | Description |
|---------|-------------|
| `bashrc-help` | Display help and available commands |
| `bashrc-version` | Show current version and check for updates |
| `updatebash` | Update to latest version from repository |
| `list-aliases` | List all available aliases |
| `list-functions` | List all custom functions |
| `restorebash --list` | Show available backups |
| `restorebash --latest` | Restore most recent backup |
| `extract <file>` | Extract various archive formats |

