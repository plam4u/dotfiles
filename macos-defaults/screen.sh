#!/bin/bash

defaults write com.apple.screencapture "show-thumbnail" -bool NO
defaults write com.apple.screencapture "target" -string "clipboard"

# Disable shadow in screenshots
defaults write com.apple.screencapture "disable-shadow" -bool YES

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver "askForPassword" -int 1
defaults write com.apple.screensaver "askForPasswordDelay" -int 0

# Enable subpixel font rendering on non-Apple LCDs
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults write NSGlobalDomain "AppleFontSmoothing" -int 1


