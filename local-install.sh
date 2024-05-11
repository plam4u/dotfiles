#!/bin/bash


if [ -x /opt/homebrew/bin/brew ]; then
	eval $(/opt/homebrew/bin/brew shellenv)
	echo $HOMEBREW_PREFIX
	echo $(which brew)
fi
