#!/bin/bash

defaults write NSGlobalDomain "AppleShowAllExtensions" -bool YES

defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"
defaults write com.apple.finder "AppleShowAllFiles" -bool YES
defaults write com.apple.finder "ShowPathbar" -bool YES
defaults write com.apple.finder "ShowStatusBar" -bool YES
defaults write com.apple.finder "NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow" -bool YES
defaults write com.apple.finder "_FXSortFoldersFirst" -bool YES
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool NO
defaults write com.apple.finder "WarnOnEmptyTrash" -bool NO
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool NO
defaults write com.apple.finder "ShowRecentTags" -bool NO
defaults write com.apple.finder "SidebarShowingiCloudDesktop" -bool NO
defaults write com.apple.finder "NewWindowTarget" -string "PfLo"
defaults write com.apple.finder "NewWindowTargetPath" -string "file:///Users/$USER/Downloads/"
defaults write com.apple.finder "NSNavLastRootDirectory" -string "~/Downloads"
defaults write com.apple.finder "SidebarZoneOrder1" -array "icloud_drive" favorites devices tags

