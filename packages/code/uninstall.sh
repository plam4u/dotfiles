#!/usr/bin/env bash

brew uninstall visual-studio-code

rm -rf ~/.vscode
rm -rf ~/Library/Application\ Support/Code
rm -rf ~/Library/Caches/com.microsoft.VSCode
rm -rf ~/Library/Saved\ Application\ State/com.microsoft.VSCode.savedState
if [[ -e /opt/homebrew/bin/code ]]; then
  rm /opt/homebrew/bin/code
fi
git clean -fdX "stow/Library/Application Support/Code"
