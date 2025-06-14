#!/usr/bin/env bash

# change permissions to allow the current user to install packages
sudo chown -R "$(whoami)":admin /usr/local /opt/homebrew
brew install --cask mactex
