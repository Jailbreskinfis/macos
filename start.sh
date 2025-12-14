#!/bin/bash

#Downloads
curl -s -o login.sh -L "https://raw.githubusercontent.com/JohnnyNetsec/github-vm/main/mac/login.sh"

#Disable spotlight indexing
sudo mdutil -i off -a

#Create new account
sudo dscl . -create /Users/runneradmin
sudo dscl . -create /Users/runneradmin UserShell /bin/bash
sudo dscl . -create /Users/runneradmin RealName Runner_Admin
sudo dscl . -create /Users/runneradmin UniqueID 1001
sudo dscl . -create /Users/runneradmin PrimaryGroupID 80
sudo dscl . -create /Users/runneradmin NFSHomeDirectory /Users/runneradmin
sudo dscl . -passwd /Users/runneradmin P@ssw0rd!
sudo dscl . -passwd /Users/runneradmin P@ssw0rd!
sudo createhomedir -c -u runneradmin > /dev/null
sudo dscl . -append /Groups/admin GroupMembership runneradmin

#Install AnyDesk
echo "Installing AnyDesk..."
brew install --cask anydesk

#Wait for AnyDesk to initialize
echo "Waiting for AnyDesk to initialize..."
sleep 5

#Start AnyDesk service
echo "Starting AnyDesk..."
open -a AnyDesk

#Wait for AnyDesk to fully start
sleep 10

#Get AnyDesk ID
echo "========================================="
echo "Getting AnyDesk ID..."
ANYDESK_ID=$(echo 'get' | /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --get-id 2>/dev/null)

if [ -z "$ANYDESK_ID" ]; then
    echo "Trying alternative method to get AnyDesk ID..."
    sleep 5
    ANYDESK_ID=$(defaults read com.philandro.anydesk ad.anynet.id 2>/dev/null)
fi

if [ ! -z "$ANYDESK_ID" ]; then
    echo "========================================="
    echo "AnyDesk ID: $ANYDESK_ID"
    echo "========================================="
    echo "Use this ID to connect to this machine"
    echo "Password: P@ssw0rd!"
    echo "========================================="
else
    echo "Could not retrieve AnyDesk ID automatically."
    echo "Please open AnyDesk application to see the ID"
    echo "Password: P@ssw0rd!"
fi

#Set unattended access password (optional)
echo "P@ssw0rd!" | /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --set-password

#Keep script running to display ID
echo ""
echo "AnyDesk is running. Keep this terminal open."
echo "Press Ctrl+C to exit"
tail -f /dev/null
