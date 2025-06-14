#!/usr/bin/env bash

brew install libyaml # dependencies for ruby
asdf plugin add ruby
asdf install ruby latest
asdf set --home ruby latest

source "$HOME"/.zshrc
