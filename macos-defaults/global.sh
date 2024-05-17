#!/bin/bash

defaults write NSGlobalDomain "AppleShowAllExtensions" -bool YES
defaults write NSGlobalDomain "AppleWindowTabbingMode" -string 'always'

# restore windows from last session
defaults write NSGlobalDomain "NSQuitAlwaysKeepsWindows" -bool YES

# disable accented characters popup on key hold
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool NO

# <int> x 15 ms (e.g. 10 x 15 = 150 ms, 1 x 15 = 15 ms)
defaults write NSGlobalDomain "InitialKeyRepeat" -int 10
defaults write NSGlobalDomain "KeyRepeat" -int 1

# drag window from anywhere
defaults write NSGlobalDomain "NSWindowShouldDragOnGesture" -bool YES
