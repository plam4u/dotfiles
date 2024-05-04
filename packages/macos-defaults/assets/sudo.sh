#!/usr/bin/env bash

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# turn firewall on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# set timezone to Madrid
sudo systemsetup -settimezone Europe/Madrid

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Show the /Volumes folder
sudo chflags nohidden /Volumes

# Show language menu in the top right corner of the boot screen
sudo defaults write "/Library/Preferences/com.apple.loginwindow" showInputMenu -bool true
