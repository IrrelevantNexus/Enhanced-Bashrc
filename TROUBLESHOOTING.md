# Troubleshooting Guide

Common issues and their solutions for Enhanced Bash Configuration.

---

## Installation Issues

### Issue: Permission Denied Errors

**Symptoms:**
```
Error: No write permission in /home/user
Failed to copy .bashrc. Check permissions and disk space.
```

**Solutions:**
1. Check home directory ownership:
   ```bash
   ls -ld ~
   # Should show your username as owner
   ```

2. Fix permissions if needed:
   ```bash
   chmod u+w ~/.bashrc ~/.bash_profile ~/.bashrc-custom
   chmod u+w ~/.config/bashrc/
   ```

3. If on a shared system, contact your administrator

---

### Issue: Git Pull Fails During Update

**Symptoms:**
```
Error: git is not installed
Error: /opt/bashrc is not a git repository
Update failed. Please check your network connection
```

**Solutions:**
1. If git is not installed:
   ```bash
   # RHEL/CentOS
   sudo yum install git
   
   # Ubuntu/Debian
   sudo apt-get install git
   ```

2. If directory is not a git repository:
   - Download the latest version manually
   - Or clone the repository properly:
     ```bash
     cd /opt
     sudo rm -rf bashrc
     sudo git clone [repository-url] bashrc
     ```

3. If network issues:
   - Check internet connection
   - Try again later
   - Use manual installation instead

---

### Issue: Installation Completes But Nothing Changes

**Symptoms:**
- Ran `./INSTALL.sh` successfully
- Terminal looks the same after restart
- `updatebash` command not found

**Solutions:**
1. Check if `.bashrc` is being loaded:
   ```bash
   echo $BASH_VERSION  # Should show bash version
   ```

2. Manually source the file:
   ```bash
   source ~/.bashrc
   ```

3. Check for conflicting files:
   ```bash
   ls -la ~ | grep -E '\.(profile|bash_profile|bash_login)'
   ```
   If `.profile` exists, it might override `.bash_profile`

4. Verify installation:
   ```bash
   cat ~/.bashrc | head -20
   # Should show "Enhanced Bash Configuration" header
   ```

5. Try logging out and back in (not just closing terminal)

---

## Prompt Issues

### Issue: Prompt Shows Weird Characters

**Symptoms:**
```
�[32m�[0m user@host �[34m~/path�[0m $
```

**Causes:**
- Terminal doesn't support ANSI color codes
- Terminal encoding is not UTF-8

**Solutions:**
1. Check terminal type:
   ```bash
   echo $TERM
   # Should be something like: xterm-256color
   ```

2. Set proper terminal:
   ```bash
   export TERM=xterm-256color
   # Add to ~/.bashrc-custom to make permanent
   ```

3. Check encoding:
   ```bash
   locale
   # Should show UTF-8 encoding
   ```

4. Switch to a better terminal emulator:
   - GNOME Terminal (recommended for RHEL/CentOS)
   - Konsole (for KDE)
   - iTerm2 (for macOS)

---

### Issue: Git Status Not Showing in Prompt

**Symptoms:**
- Git branch/status missing from prompt
- Prompt looks incomplete

**Solutions:**
1. Verify you're in a git repository:
   ```bash
   git status
   ```

2. Check if git is installed:
   ```bash
   which git
   git --version
   ```

3. Check if prompt function is loaded:
   ```bash
   type set_bash_prompt
   # Should show function definition
   ```

4. Manually reload prompt configuration:
   ```bash
   source ~/.config/bashrc/prompt.rc
   set_bash_prompt
   ```

---

### Issue: Prompt Too Long/Wrapping Incorrectly

**Symptoms:**
- Prompt text wraps to new line badly
- Cursor position is wrong when editing long commands
- Text overwrites itself

**Causes:**
- Terminal width is too narrow
- Non-printing characters not properly escaped
- Very long branch names or paths

**Solutions:**
1. Increase terminal width (80+ characters recommended)

2. Shorten your branch names:
   ```bash
   git branch -m very-long-branch-name shorter
   ```

3. Customize prompt in `~/.bashrc-custom`:
   ```bash
   # Use shorter hostname
   export SHORT_HOSTNAME="${HOSTNAME%%.*}"
   
   # Truncate long paths
   PROMPT_DIRTRIM=2  # Shows only last 2 directories
   ```

---

## Performance Issues

### Issue: Terminal Starts Slowly

**Symptoms:**
- Several second delay when opening new terminal
- Shell takes time to become responsive

**Solutions:**
1. Profile your bashrc startup time:
   ```bash
   time bash -c exit
   # Should be under 0.5 seconds
   ```

2. Disable expensive operations temporarily:
   ```bash
   # In ~/.bashrc-custom, comment out:
   # - pyenv initialization
   # - conda initialization
   # - Complex PROMPT_COMMAND
   ```

3. Check for network timeouts:
   ```bash
   # Look for commands that might wait for network
   # Like Kerberos ticket renewal
   ```

4. Use lazy loading for large tools:
   ```bash
   # Instead of: eval "$(pyenv init -)"
   # Use lazy loading wrapper
   ```

---

### Issue: Command History is Slow

**Symptoms:**
- Delay when pressing up/down arrows
- `history` command takes long time

**Solutions:**
1. Check history file size:
   ```bash
   wc -l ~/.bash_history
   # If over 500K lines, it might be too large
   ```

2. Trim history file:
   ```bash
   cp ~/.bash_history ~/.bash_history.backup
   tail -100000 ~/.bash_history.backup > ~/.bash_history
   ```

3. Reduce HISTSIZE in `~/.config/bashrc/settings.rc`:
   ```bash
   export HISTSIZE=10000  # Instead of 1000000
   ```

---

## Update Issues

### Issue: Update Overwrites My Customizations

**Symptoms:**
- Custom aliases disappeared after update
- Custom prompt settings gone

**Solutions:**
1. **Prevention:** Set ALLOWUPDATE='False' in files you customize:
   ```bash
   # In ~/.bashrc
   ALLOWUPDATE='False'
   ```

2. **Recovery:** Restore from backup:
   ```bash
   restorebash --list
   restorebash --latest
   ```

3. **Best Practice:** Put all customizations in `~/.bashrc-custom`:
   - This file is never overwritten by default
   - Safe for all personal customizations

---

### Issue: Update Says "No Updates Available" But I Know There Are

**Symptoms:**
```
You are already using the up to date version
```

**Solutions:**
1. Check if repository is actually updated:
   ```bash
   cd /opt/bashrc
   git fetch
   git status
   ```

2. Force update:
   ```bash
   cd /opt/bashrc
   git pull --force
   ./INSTALL.sh
   ```

3. Check file checksums manually:
   ```bash
   diff ~/.bashrc /opt/bashrc/.bashrc
   ```

---

## Alias and Function Issues

### Issue: Alias Not Working

**Symptoms:**
```
bash: aliasname: command not found
```

**Solutions:**
1. Check if alias exists:
   ```bash
   alias aliasname
   ```

2. List all aliases:
   ```bash
   alias | grep aliasname
   ```

3. Reload configuration:
   ```bash
   source ~/.bashrc
   ```

4. Check if alias is defined in custom file:
   ```bash
   grep aliasname ~/.bashrc-custom ~/.config/bashrc/bash_aliases.rc
   ```

---

### Issue: `extract` Function Fails

**Symptoms:**
```
I don't know how to extract 'file.xyz'
```

**Solutions:**
1. Check file type:
   ```bash
   file yourfile.ext
   ```

2. Install required tools:
   ```bash
   # For .rar files
   sudo yum install unrar
   
   # For .7z files
   sudo yum install p7zip
   ```

3. Use specific extraction command:
   ```bash
   # For .tar.gz
   tar -xzf file.tar.gz
   
   # For .zip
   unzip file.zip
   ```

---

## Python Integration Issues

### Issue: Python Virtualenv Not Showing in Prompt

**Symptoms:**
- Virtualenv is active but not displayed in prompt
- No `[V:envname]` indicator

**Solutions:**
1. Check if virtualenv is actually active:
   ```bash
   echo $VIRTUAL_ENV
   ```

2. Manually trigger prompt update:
   ```bash
   set_bash_prompt
   ```

3. Check if prompt.rc is loaded:
   ```bash
   type set_virtualenv
   ```

---

### Issue: `python` Command Not Found After Installation

**Symptoms:**
```
bash: python: command not found
```

**Causes:**
- Python 3 is installed as `python3`, not `python`
- The alias isn't loaded yet

**Solutions:**
1. Check if Python 3 is installed:
   ```bash
   python3 --version
   ```

2. Reload bashrc:
   ```bash
   source ~/.bashrc
   ```

3. Manually add alias:
   ```bash
   echo "alias python='python3'" >> ~/.bashrc-custom
   source ~/.bashrc
   ```

---

## GNOME Integration Issues

### Issue: GNOME Settings Not Applied

**Symptoms:**
- Desktop theme unchanged
- Keyboard shortcuts not working

**Solutions:**
1. Check if dconf is installed:
   ```bash
   which dconf
   ```

2. Manually apply settings:
   ```bash
   dconf load / < ~/.config/dconf.custom
   ```

3. Log out and log back in

---

## SSH and Remote Terminal Issues

### Issue: Colors Don't Work Over SSH

**Symptoms:**
- Terminal is black and white when SSHing to server
- Colors work locally but not remotely

**Solutions:**
1. Check TERM variable on remote:
   ```bash
   ssh user@host 'echo $TERM'
   ```

2. Force color terminal:
   ```bash
   ssh -t user@host
   ```

3. Set TERM in SSH config:
   ```bash
   # In ~/.ssh/config
   Host *
       SetEnv TERM=xterm-256color
   ```

---

## Getting Help

### Still Having Issues?

1. **Check system information:**
   ```bash
   bash --version
   echo $TERM
   uname -a
   ```

2. **Generate diagnostic report:**
   ```bash
   cat > ~/bashrc-debug.txt << 'EOF'
   Bash Version: $(bash --version | head -1)
   OS: $(cat /etc/os-release | grep PRETTY_NAME)
   Terminal: $TERM
   Shell: $SHELL
   
   Files present:
   $(ls -la ~/ | grep -E '\.bash')
   
   Current errors:
   $(bash -c 'source ~/.bashrc' 2>&1)
   EOF
   
   bash ~/bashrc-debug.txt > ~/bashrc-diagnostic.txt
   ```

3. **Report the issue:**
   - Include your diagnostic information
   - Describe what you expected vs. what happened
   - Include any error messages
   - Mention your OS and terminal emulator

### Contact

- **Issues:** [Your GitHub/GitLab issues URL]
- **Documentation:** See README.md

---

## Advanced Troubleshooting

### Debugging Bash Execution

1. **Enable debug mode:**
   ```bash
   bash -x ~/.bashrc
   # Shows each command as it executes
   ```

2. **Check for syntax errors:**
   ```bash
   bash -n ~/.bashrc
   # Checks syntax without executing
   ```

3. **Find slow commands:**
   ```bash
   PS4='+ $(date "+%s.%N")\011 ' bash -x ~/.bashrc 2>&1 | tee debug.log
   # Timestamps each command
   ```

### Clean Installation

If all else fails, start fresh:

```bash
# Backup current configuration
mkdir ~/bashrc-backup-$(date +%Y%m%d)
cp ~/.bashrc ~/.bash_profile ~/.bashrc-custom ~/bashrc-backup-$(date +%Y%m%d)/

# Remove current configuration
rm ~/.bashrc ~/.bash_profile ~/.bashrc-custom
rm -rf ~/.config/bashrc

# Reinstall
cd /opt/bashrc
./INSTALL.sh
```

---

## Prevention Tips

1. **Always test changes in a new terminal first**
2. **Set ALLOWUPDATE='False' in files you modify**
3. **Keep customizations in ~/.bashrc-custom**
4. **Review backups before updates**
5. **Use --preview flag before installing updates**
