#!/usr/bin/env bash

brew install stow

# TODO: backup existing files before stowing
#
# link: stow-$(OS)
# 	for FILE in $$(\ls -A rc); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then mv -v $(HOME)/$$FILE{,.bak}; fi; done
# 	mkdir -p $(XDG_CONFIG_HOME)
# 	stow -t $(HOME) rc
# 	stow -t $(XDG_CONFIG_HOME) conf

stow -t "$HOME" .
