#!/usr/bin/env bash

# Hack to fix broken paths because of paralle Intel homebrew installation.
eval $(/opt/homebrew/bin/brew shellenv)

source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
