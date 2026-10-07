#!/usr/bin/env bash

git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom doctor
