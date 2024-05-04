#!/usr/bin/env bash

brew tap candid82/brew
brew tap yqrashawn/goku

brew install yqrashawn/goku/goku
softwareupdate --install-rosetta --agree-to-license
brew services start goku
