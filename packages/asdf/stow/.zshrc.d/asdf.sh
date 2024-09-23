#!/usr/bin/env bash

[ -f ~/.asdf/asdf.sh ] && source ~/.asdf/asdf.sh

# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)

# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

export PATH="$HOME/.asdf/shims:$PATH"

