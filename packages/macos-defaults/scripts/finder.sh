#!/bin/bash

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder "QuitMenuItem" -bool YES

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder "DisableAllAnimations" -bool YES

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool true
defaults write com.apple.finder "ShowHardDrivesOnDesktop" -bool true
defaults write com.apple.finder "ShowMountedServersOnDesktop" -bool true
defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"

# Icon View   : `icnv`
# List View   : `Nlsv`
# Column View : `clmv`
# Cover Flow  : `Flwv`
defaults write com.apple.finder "FXPreferredViewStyle" -string 'Nlsv'

# Writing of .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices "DSDontWriteNetworkStores" -bool YES
defaults write com.apple.desktopservices "DSDontWriteUSBStores" -bool YES

# Disable disk image verification
defaults write com.apple.frameworks.diskimages "skip-verify" -bool true
defaults write com.apple.frameworks.diskimages "skip-verify-locked" -bool true
defaults write com.apple.frameworks.diskimages "skip-verify-remote" -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages "auto-open-ro-root" -bool true
defaults write com.apple.frameworks.diskimages "auto-open-rw-root" -bool true
defaults write com.apple.finder "OpenWindowForNewRemovableDisk" -bool true

# Enable snap-to-grid for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Increase grid spacing for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Increase the size of icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist

# Expand save panel by default
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode" -bool YES
defaults write NSGlobalDomain "NSNavPanelExpandedStateForSaveMode2" -bool YES

# Expand print panel by default
defaults write NSGlobalDomain "PMPrintingExpandedStateForPrint" -bool YES
defaults write NSGlobalDomain "PMPrintingExpandedStateForPrint2" -bool YES

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool NO

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool YES

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices "LSQuarantine" -bool NO

# Set Help Viewer windows to non-floating mode
defaults write com.apple.helpviewer "DevMode" -bool YES

# Disable the warning before emptying the Trash
defaults write com.apple.finder "WarnOnEmptyTrash" -bool false

defaults write NSGlobalDomain "AppleShowAllExtensions" -bool YES
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
defaults write com.apple.finder "CreateDesktop" -bool NO
# defaults write com.apple.finder "_FXShowPosixPathInTitle" -bool YES
defaults write com.apple.finder "_FXSortFoldersFirst" -bool YES
defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool YES

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
# Skipped because it asks for password
# sudo chflags nohidden /Volumes

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder "FXInfoPanesExpanded" -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true
