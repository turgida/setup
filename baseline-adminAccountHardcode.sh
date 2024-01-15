#!/bin/zsh
# Uncomment this for verbose debug
#set -x 

#############
# Functions #
#############

# Verify we are running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "ERROR: This script must be run as root **EXITING**"
  exit 1
fi

#############
# Variables #
#############

variable1="Blu3Duck4U2?1901"

# Path to Baseline Scripts directory
BaselineScripts="/usr/local/Baseline/Scripts"

# Create admin user
username=admin.cig

######################
# Script Starts Here #
######################

echo "Creating new local admin account [$username]"
# Create User and add to admins
dscl . -create /Users/$username
dscl . -create /Users/$username UserShell /bin/bash
dscl . -create /Users/$username RealName "Administrator Account"
dscl . -create /Users/$username UniqueID "510"
dscl . -create /Users/$username PrimaryGroupID 20
dscl . -create /Users/$username NFSHomeDirectory /Users/$username
dscl . -passwd /Users/$username $variable1
dscl . -append /Groups/admin GroupMembership $username
