# /opt/bashrc Quick Reference

## For Regular Users

### Update the bashrc repository
```bash
bashrc-update
```
or
```bash
bashrc-git pull
```

### Check status
```bash
bashrc-git status
```

### View recent changes
```bash
bashrc-git log --oneline -10
```

### View differences
```bash
bashrc-git diff
```

## Why Use the Wrapper?

The `bashrc-git` wrapper automatically fixes file permissions after Git operations to ensure all users can continue to access and update the repository. Without it, the first person to run `git pull` might lock out other users due to file ownership changes.

## What It Does

When you run `bashrc-git <command>`:
1. Changes to `/opt/bashrc` directory
2. Runs your git command
3. If successful, automatically fixes all file permissions
4. Shows you a confirmation message

## Common Issues

**"Permission denied" errors**: Run `bashrc-git status` to fix permissions, or contact your administrator.

**Forgot to use wrapper**: If you ran `git pull` directly and others are now locked out, run `bashrc-git status` to fix it.
