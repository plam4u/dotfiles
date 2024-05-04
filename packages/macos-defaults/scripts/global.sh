#!/bin/bash

# turn firewall on
# sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# set timezone to Madrid
# sudo systemsetup -settimezone Europe/Madrid

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "

# Always show scrollbars
defaults write NSGlobalDomain "AppleShowScrollBars" -string "Always"

defaults write NSGlobalDomain "AppleWindowTabbingMode" -string 'always'
defaults write NSGlobalDomain "AppleInterfaceStyle" -string 'Dark'
defaults write com.apple.dock "region" -string 'ES'

# restore windows from last session
defaults write NSGlobalDomain "NSQuitAlwaysKeepsWindows" -bool YES

# drag window from anywhere
defaults write NSGlobalDomain "NSWindowShouldDragOnGesture" -bool YES

# date format
defaults write NSGlobalDomain "AppleICUDateFormatStrings" '<dict><key>1</key><string>y-MM-dd</string></dict>'

defaults write NSGlobalDomain "AppleFirstWeekday" '<dict><key>gregorian</key><integer>2</integer></dict>'
defaults write NSGlobalDomain "AppleLanguages" '<array><string>en-US</string></array>'
defaults write NSGlobalDomain "AppleLocale" -string 'en_US@rg=eszzzz'
defaults write NSGlobalDomain "AppleMeasurementUnits" -string 'Centimeters'
defaults write NSGlobalDomain "AppleMetricUnits" -bool YES
defaults write NSGlobalDomain "AppleTemperatureUnits" -string 'Celsius'
defaults write NSGlobalDomain "AppleLiveTextEnabled" -bool YES

