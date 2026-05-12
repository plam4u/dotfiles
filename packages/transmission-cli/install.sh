#!/usr/bin/env bash

brew install transmission-cli

# ==> transmission-cli
# This formula only installs the command line utilities.
#
# Transmission.app can be downloaded directly from the website:
#   https://www.transmissionbt.com/
#
# Alternatively, install with Homebrew Cask:
#   brew install --cask transmission
#
# To start transmission-cli now and restart at login:
#   brew services start transmission-cli
# Or, if you don't want/need a background service you can just run:
#   /opt/homebrew/opt/transmission-cli/bin/transmission-daemon --foreground --config-dir /opt/homebrew/var/transmission/ --log-info --logfile /opt/homebrew/var/transmission/transmission-daemon.log
