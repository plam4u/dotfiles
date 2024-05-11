#!/bin/bash


if [ -x /opt/homebrew/bin/brew ]; then
	# export homebrew variables for current script
	eval $(/opt/homebrew/bin/brew shellenv)
	brew install --file $HOME/.dotfiles/Brewfile
fi
