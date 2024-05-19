#!/bin/bash

defaults write com.apple.dock "autohide" -bool YES
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


source $HOME/.zprofile
if [ -x "$(command -v dockutil)" ]; then
    dockutil -r all --no-restart
    dockutil -a /System/Applications/Calendar.app/ --no-restart
    dockutil -a /System/Applications/Reminders.app/ --no-restart
    dockutil -a /System/Applications/Notes.app/ --no-restart
    dockutil -a /Applications/Safari.app/ --no-restart
    dockutil -a /System/Applications/Mail.app/ --restart
fi

