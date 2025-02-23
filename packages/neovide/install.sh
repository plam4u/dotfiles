#!/usr/bin/env bash
# source: https://neovide.dev/index.html

brew install --cask neovide

# When you want Homebrew binaries accessible to GUI applications
# launched via Finder, Spotlight, or macOS services
# (which don’t always inherit shell PATH).
sudo launchctl config user path "$(brew --prefix)/bin:${PATH}"
