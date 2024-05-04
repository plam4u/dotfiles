#!/bin/bash

# disable accented characters popup on key hold
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool NO

# <int> x 15 ms (e.g. 10 x 15 = 150 ms, 1 x 15 = 15 ms)
defaults write NSGlobalDomain "InitialKeyRepeat" -int 10
defaults write NSGlobalDomain "KeyRepeat" -int 1

# Use F1, F2, etc. as standard function keys
defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool YES

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain "NSAutomaticCapitalizationEnabled" -bool NO

# Disable automatic capitalization as it’s annoying when typing code
defaults write NSGlobalDomain "NSAutomaticCapitalizationEnabled" -bool NO

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain "NSAutomaticDashSubstitutionEnabled" -bool NO

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain "NSAutomaticPeriodSubstitutionEnabled" -bool NO

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain "NSAutomaticQuoteSubstitutionEnabled" -bool NO

# Disable auto-correct
defaults write NSGlobalDomain "NSAutomaticSpellingCorrectionEnabled" -bool NO

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "Clicking" -bool YES
defaults -currentHost write NSGlobalDomain "com.apple.mouse.tapBehavior" -int 1
defaults write NSGlobalDomain "com.apple.mouse.tapBehavior" -int 1

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Show language menu in the top right corner of the boot screen
# sudo defaults write "/Library/Preferences/com.apple.loginwindow" showInputMenu -bool true

