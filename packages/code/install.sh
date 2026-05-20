#!/usr/bin/env bash

pm stow code
brew install --cask visual-studio-code

for e in vim godot haxe love2d css; do
  cat "extensions/$e" | xargs -L 1 code --install-extension
done
