#!/bin/bash

[[ $1 == "--dev" ]] && DEV_MODE="1"

# make sure that Homebrew is available
if [ ! -x /opt/homebrew/bin/brew ]; then
    echo "Can't find /opt/homebrew/bin/brew. Installation can't continue without 'brew'!"
    exit 1
fi

# some installs require sudo (e.g. karabiner-elements)
if [ -z "$DEV_MODE" ]; then
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

# export homebrew variables for current script.
eval $(/opt/homebrew/bin/brew shellenv)

# install Brewfile
brew bundle install --file $HOME/.dotfiles/Brewfile
if [ -z "$DEV_MODE" ]; then
    brew bundle install --file $HOME/.dotfiles/Brewfile-basics
fi

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

# start karabiner-goku service to watch for changes
if [ -x "$(command -v goku)" && -z "$DEV_MODE"]; then

    # install rosetta for backward compatibility (e.g. to run goku)
    softwareupdate --install-rosetta --agree-to-license

    brew services start goku
else
    echo "goku executable not found. Skipping..."
fi

if [ -z "$DEV_MODE"]; then
    # Installed here because
    # QMK throws warnings when installed using "brew bundle"
    brew tap qmk/qmk
    brew install qmk/qmk/qmk
fi

echo
echo "local-install.sh: \033[32mOK!\033[0m"
echo

for script in macos-defaults/*; do
    echo
    echo "\033[32mRunning $script...\033[0m"
    sh $script
done

echo
echo "macOS user defaults: \033[32mOK!\033[0m"
echo
