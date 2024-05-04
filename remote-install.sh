#!/bin/bash

# Install homebrew.
# This will install also install the required Command Line Tools (CLT) for Xcode.
# CLT packs git and make binaries.
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone dotfiles to ~/.dotfiles
git clone https://github.com/plam4u/dotfiles ~/dotfiles
