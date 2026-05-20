#!/usr/bin/env bash

pm stow code
brew install --cask visual-studio-code

for e in extensions-base extensions-godot extensions-haxe extensions-love2d extensions-others; do
  cat "extensions/$e" | xargs -L 1 code --install-extension
done
