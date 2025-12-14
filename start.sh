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

echo "========================================="
echo "Setting up remote access..."
echo "========================================="

#Install AnyDesk
echo "Installing AnyDesk..."
brew install --cask anydesk

#Grant AnyDesk accessibility permissions
echo "Granting AnyDesk permissions..."
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT or REPLACE INTO access VALUES('kTCCServiceAccessibility','com.philandro.anydesk',0,2,3,1,NULL,NULL,0,'UNUSED',NULL,0,1541440109);" 2>/dev/null
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT or REPLACE INTO access VALUES('kTCCServiceScreenCapture','com.philandro.anydesk',0,2,3,1,NULL,NULL,0,'UNUSED',NULL,0,1541440109);" 2>/dev/null
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "INSERT or REPLACE INTO access VALUES('kTCCServicePostEvent','com.philandro.anydesk',0,2,3,1,NULL,NULL,0,'UNUSED',NULL,0,1541440109);" 2>/dev/null

#Disable SIP protection for TCC (if needed on newer macOS)
sudo tccutil reset All com.philandro.anydesk 2>/dev/null

#Start AnyDesk service
echo "Starting AnyDesk..."
open -a AnyDesk 2>/dev/null

#Wait for AnyDesk to fully start
sleep 10

#Get AnyDesk ID
echo "Getting AnyDesk ID..."
ANYDESK_ID=$(echo 'get' | /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --get-id 2>/dev/null)

if [ -z "$ANYDESK_ID" ]; then
    echo "Trying alternative method to get AnyDesk ID..."
    sleep 5
    ANYDESK_ID=$(defaults read com.philandro.anydesk ad.anynet.id 2>/dev/null)
fi

ANYDESK_SUCCESS=false
if [ ! -z "$ANYDESK_ID" ]; then
    echo "========================================="
    echo "✓ AnyDesk ID: $ANYDESK_ID"
    echo "Password: P@ssw0rd!"
    echo "========================================="
    
    #Configure unattended access with password
    echo "Configuring unattended access..."
    echo "P@ssw0rd!" | /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --set-password
    
    #Enable unattended access (disable acceptance requirement)
    /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --set-setting ad.security.interactive_access 1
    /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --set-setting ad.security.unattended_access_allow 1
    
    ANYDESK_SUCCESS=true
else
    echo "⚠ Could not retrieve AnyDesk ID. Setting up VNC/RDP as fallback..."
fi

#Setup VNC/RDP as fallback
echo "========================================="
echo "Setting up VNC/RDP fallback..."
echo "========================================="

#Enable VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 
echo runnerrdp | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

#Start VNC/reset changes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

#Install ngrok
echo "Installing ngrok..."
brew install --cask ngrok

#Configure ngrok and start it
if [ ! -z "$1" ]; then
    ngrok authtoken $1
    ngrok tcp 5900 --region=in > /tmp/ngrok.log 2>&1 &
    NGROK_PID=$!
    
    #Wait for ngrok to start
    sleep 5
    
    #Get ngrok URL
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"tcp://[^"]*' | cut -d'"' -f4 | head -n1)
    
    if [ ! -z "$NGROK_URL" ]; then
        echo "========================================="
        echo "✓ VNC/RDP Connection Info:"
        echo "URL: $NGROK_URL"
        echo "Username: runneradmin"
        echo "Password: P@ssw0rd!"
        echo "VNC Password: runnerrdp"
        echo "========================================="
    else
        echo "⚠ Could not get ngrok URL. Check /tmp/ngrok.log"
    fi
else
    echo "⚠ No ngrok authtoken provided. Skipping ngrok setup."
    echo "VNC is enabled on port 5900 (local only)"
fi

#Summary
echo ""
echo "========================================="
echo "REMOTE ACCESS SUMMARY"
echo "========================================="
if [ "$ANYDESK_SUCCESS" = true ]; then
    echo "PRIMARY: AnyDesk"
    echo "  ID: $ANYDESK_ID"
    echo "  Password: P@ssw0rd!"
    echo ""
fi
echo "FALLBACK: VNC/RDP"
if [ ! -z "$NGROK_URL" ]; then
    echo "  URL: $NGROK_URL"
else
    echo "  Local Port: 5900"
fi
echo "  Username: runneradmin"
echo "  Password: P@ssw0rd!"
echo "  VNC Password: runnerrdp"
echo "========================================="
echo ""
echo "Keep this terminal open."
echo "Press Ctrl+C to exit"

#Keep script running
tail -f /dev/null
