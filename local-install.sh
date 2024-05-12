#!/bin/bash

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ -x /opt/homebrew/bin/brew ]; then
	# export homebrew variables for current script
	eval $(/opt/homebrew/bin/brew shellenv)

	# install Brewfile
	brew bundle install --file $HOME/.dotfiles/Brewfile
else
	echo "Brew not available. Exiting..."
	exit 1
fi

(
	cd stow
	stow -t $HOME *
)

# start karabiner-goku service to watch for changes
brew services start goku

echo "Finished local installation!"
echo
