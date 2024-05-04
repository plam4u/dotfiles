#!/usr/bin/env bash

export ZSH="$HOME/.oh-my-zsh"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
ZSH_DISABLE_COMPFIX=true

ZSH_THEME="avit" # "robbyrussell"

plugins=(
	aliases
	alias-finder
	asdf
	git
	gitignore
	tig
	virtualenv
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
