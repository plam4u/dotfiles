#!/usr/bin/env bash

pm stow code
brew install --cask visual-studio-code

for e in base customize godot haxe love2d; do
  cat "extensions/$e" | xargs -L 1 code --install-extension
done
