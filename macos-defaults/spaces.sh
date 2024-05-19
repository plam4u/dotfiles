#!/bin/bash

defaults write NSGlobalDomain "AppleSpacesSwitchOnActivate" -bool YES
defaults write com.apple.spaces "spans-displays" -bool NO
defaults write com.apple.dock "expose-group-apps" -bool YES
defaults write com.apple.dock "mru-spaces" -bool NO
