#!/bin/bash

# make sure that Homebrew is available
if [ ! -x /opt/homebrew/bin/brew ]; then
    echo "Can't find /opt/homebrew/bin/brew. Installation can't continue without 'brew'!"
    exit 1
fi

# some installs require sudo (e.g. karabiner-elements)
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# export homebrew variables for current script.
eval $(/opt/homebrew/bin/brew shellenv)

# install Brewfile
brew bundle install --file $HOME/.dotfiles/Brewfile

if [ -x "$(command -v stow)" ]; then
    # Subshells: Parentheses can also be used to create subshells, 
    # which execute commands in a separate child process.
    # This can be useful for isolating changes to the environment 
    # or executing commands in a different context
    (
        # stow contains "packages".
        # install all packages
        # by using the * to expand dirs
        cd stow
        stow -t $HOME *
    )
fi

# install rosetta for backward compatibility (e.g. to run goku)
softwareupdate --install-rosetta --agree-to-license

# start karabiner-goku service to watch for changes
if [ -x "$(command -v goku)" ]; then
    brew services start goku
else
    echo "goku executable not found. Skipping..."
fi

# QMK throws warnings when installed using "brew bundle"
brew tap qmk/qmk
brew install qmk/qmk/qmk

echo
echo "local-install.sh: OK!"
echo

sh local-install-macos.sh

echo
echo "macOS settings: OK!"
echo
