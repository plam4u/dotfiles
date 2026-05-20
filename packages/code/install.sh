#!/usr/bin/env bash

brew install --cask visual-studio-code
cat extensions/extensions-godot | xargs -L 1 code --install-extension
