#!/bin/bash
# Daily Check Reminder Script for macOS
# Called by launchd twice daily: morning 8:00 and evening 21:00
# Requires: Obsidian Advanced URI plugin installed in your vault

# Choose message based on time of day
HOUR=$(date +%H)
if [ "$HOUR" -lt 12 ]; then
    MSG="Good morning! Review your daily checklist and set intentions for today."
else
    MSG="Evening review: What mistakes did you make today? What traits triggered? 🌙"
fi

# CHANGE THIS to your vault ID
# Find it in Obsidian > Settings > About > scroll down to "Vault ID"
VAULT_ID="YOUR_VAULT_ID"

# Advanced URI plugin: daily=true opens or creates today's daily note
OPEN_URI="obsidian://advanced-uri?vault=${VAULT_ID}&daily=true"

# macOS dialog popup with button to open Obsidian
osascript -e "
display dialog \"$MSG\" buttons {\"Later\", \"Open Obsidian\"} default button \"Open Obsidian\" with title \"📋 Daily Check Reminder\"
if button returned of result is \"Open Obsidian\" then
    do shell script \"open '$OPEN_URI'\"
end if
" 2>/dev/null
