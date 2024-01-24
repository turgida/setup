#!/bin/zsh

# Path to SwiftDialog
dialogPath='/usr/local/bin/dialog'

"$dialogPath" \
    --title "Mandatory Password Change" \
    --message "Your screen will now go to sleep, please wake the screen and change your password at the login screen." 10 30 \
    --ontop

pmset displaysleepnow

"$dialogPath" \
    --title "Ensure password has changed" \
    --message "Please confirm your password has changed. If it has not do not continue past this screen until it has been changed. Instead, lock your screen and change it from the login prompt before continuing." 10 30 \
    --ontop