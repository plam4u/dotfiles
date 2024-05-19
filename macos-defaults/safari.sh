#!/bin/bash

defaults write com.apple.Safari "ShowFullURLInSmartSearchField" -bool YES
defaults write com.apple.Safari "ShowOverlayStatusBar" -bool YES
defaults write com.apple.Safari.SandboxBroker "ShowDevelopMenu" -bool YES
defaults write com.apple.Safari "IncludeDevelopMenu" -bool YES
defaults write com.apple.Safari "EnableEnhancedPrivacyInRegularBrowsing" -bool YES
defaults write com.apple.Safari "WebKitPreferences.privateClickMeasurementEnabled" -bool NO

