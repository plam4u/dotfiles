#!/bin/bash

defaults write com.apple.universalaccess "showToolbarButtonShapes" -bool YES
defaults write com.apple.universalaccess "reduceTransparency" -bool YES

# Use scroll gesture with the Ctrl (^) modifier key to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
# Follow the keyboard focus while zoomed in
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

