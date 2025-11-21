#!/bin/bash
## XRDP Session Manager
## Author: Mike Lilly
## Updated: 2025-01-03
##
## Purpose:
## Enables concurrent local and XRDP sessions for the same user
## by managing display conflicts and session initialization.
##
## Usage:
## Place at ~/startwm.sh for XRDP and SSH X forwarding to use at session startup
##
## Notes:
## - Some applications may have display conflicts
## - Required for XRDP multi-session support
## - Compatible with GNOME 3+ desktop environment

# Check if we're in an SSH X forwarding session
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    if [ -n "$DISPLAY" ] && [ "$DISPLAY" != ":0" ]; then
        echo "X forwarding session detected, skipping gnome-session"
        exit 0
    fi
fi

# Check if GNOME is available. Modify this for KDE Plasma or other DEs.
if command -v gnome-session &> /dev/null; then
    gnome-session
else
    echo "GNOME is not available on this system."
    exit 1
fi
