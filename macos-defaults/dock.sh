#!/bin/bash

defaults write com.apple.dock "autohide" -bool YES

# Don’t show recent applications in Dock
defaults write com.apple.dock "show-recents" -bool NO

# tl (top left), tr (top right), bl (top left), br (bottom right)

# 1: -
# 2: Mission Control
# 3: Application windows
# 4: Desktop
# 5: Start screen saver
# 6: Disable screen saver
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
# 14: Quick Note
# defaults write com.apple.dock wvous-br-corner -int 13

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock "show-process-indicators" -bool true

# Show only open applications in the Dock
# defaults write com.apple.dock static-only -bool true

# Don’t animate opening applications from the Dock
defaults write com.apple.dock "launchanim" -bool false

# Speed up Mission Control animations
defaults write com.apple.dock "expose-animation-duration" -float 0.1

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock "showhidden" -bool true

source $HOME/.zprofile
if [ -x "$(command -v dockutil)" ]; then
    dockutil -r all --no-restart
    dockutil -a /System/Applications/Calendar.app/ --no-restart
    dockutil -a /System/Applications/Reminders.app/ --no-restart
    dockutil -a /System/Applications/Notes.app/ --no-restart
    dockutil -a /Applications/Safari.app/ --no-restart
    dockutil -a /System/Applications/Mail.app/ --restart
fi

