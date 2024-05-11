#!/bin/bash

# Install brew which will install Command Line Tools for Xcode
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# Clone dotfiles to ~/.dotfiles
git clone https://github.com/plam4u/dotfiles ~/.dotfiles
