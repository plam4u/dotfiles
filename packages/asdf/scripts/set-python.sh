#!/usr/bin/env bash

brew install xz # dependencies for python
asdf plugin add python
asdf install python latest
asdf set --home python latest
