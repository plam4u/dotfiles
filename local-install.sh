#!/bin/bash

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ -x /opt/homebrew/bin/brew ]; then
	# export homebrew variables for current script
	eval $(/opt/homebrew/bin/brew shellenv)
	brew bundle install --file $HOME/.dotfiles/Brewfile
fi
