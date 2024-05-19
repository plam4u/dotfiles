#!/bin/bash

defaults write NSGlobalDomain "AppleShowAllExtensions" -bool YES
defaults write NSGlobalDomain "AppleWindowTabbingMode" -string 'always'
defaults write NSGlobalDomain "AppleInterfaceStyle" -string 'Dark'

# restore windows from last session
defaults write NSGlobalDomain "NSQuitAlwaysKeepsWindows" -bool YES

# disable accented characters popup on key hold
defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool NO

# <int> x 15 ms (e.g. 10 x 15 = 150 ms, 1 x 15 = 15 ms)
defaults write NSGlobalDomain "InitialKeyRepeat" -int 10
defaults write NSGlobalDomain "KeyRepeat" -int 1

# drag window from anywhere
defaults write NSGlobalDomain "NSWindowShouldDragOnGesture" -bool YES

# date format
defaults write NSGlobalDomain "AppleICUDateFormatString" '<dict><key>1</key><string>y-MM-dd</string></dict>'
defaults write NSGlobalDomain "AppleFirstWeekday" '<dict><key>gregorian</key><integer>2</integer></dict>'
defaults write NSGlobalDomain "AppleLanguages" '<array><string>en-US</string></array>'
defaults write NSGlobalDomain "AppleLocale" -string 'en_US@rg=eszzzz'
defaults write NSGlobalDomain "AppleMeasurementUnits" -string 'Centimeters'
defaults write NSGlobalDomain "AppleMetricUnits" -bool YES
defaults write NSGlobalDomain "AppleTemperatureUnits" -string 'Celsius'
defaults write NSGlobalDomain "AppleLiveTextEnabled" -bool YES

