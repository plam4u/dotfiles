#!/usr/bin/env bash
#
# export PATH for QMK-installed dependencies needed by QMK setup
export PATH="/opt/homebrew/opt/avr-gcc@8/bin:$PATH"
export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"

# compile from anywhere (no need to cd into qmk_firmware folder)
export QMK_HOME=~/dev/qmk_firmware
