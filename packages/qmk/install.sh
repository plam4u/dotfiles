#!/usr/bin/env bash

brew install qmk/qmk/qmk

mkdir -p ~/dev
if [ ! -d ~/dev/qmk_firmware ]; then
    echo
    echo "Cloning plam4u/qmk_firmware into ~/dev/qmk_firmware..."
    git clone git@github.com:plam4u/qmk_firmware.git ~/dev/qmk_firmware
fi

echo
echo "Running \"qmk setup -H ~/dev/qmk_firmware\"..."
(
    cd ~/dev/qmk_firmware

    # upstream is required
    git remote add upstream https://github.com/qmk/qmk_firmware.git 

    # throws an error
    git rm --cached lib/ugfx &> /dev/null
    git submodule update --init --recursive

    # export PATH for QMK-installed dependencies needed by QMK setup
    export PATH="/opt/homebrew/opt/avr-gcc@8/bin:$PATH"
    export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"

    # -H sets the QMK Home folder since by default it is ~/qmk_firmware
    qmk setup -H ~/dev/qmk_firmware

    # override local python version used by the author of keymapviz
    asdf local python latest
    pip install keymapviz 

    # compile from anywhere (no need to cd into qml_firmware folder)
    export QMK_HOME=~/dev/qmk_firmware
)
# Getting Started
# https://docs.qmk.fm/newbs_getting_started
