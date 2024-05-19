#!/bin/bash

defaults write com.apple.dock "autohide" -bool YES
defaults write com.apple.dock "show-recents" -bool NO

source $HOME/.zprofile
if [ -x "$(command -v dockutil)" ]; then
    dockutil -r all --no-restart
    dockutil -a /System/Applications/Calendar.app/ --no-restart
    dockutil -a /System/Applications/Reminders.app/ --no-restart
    dockutil -a /System/Applications/Notes.app/ --no-restart
    dockutil -a /Applications/Safari.app/ --no-restart
    dockutil -a /System/Applications/Mail.app/ --restart
fi

