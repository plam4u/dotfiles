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
  cd ~/dev/qmk_firmware || exit

  # upstream is required
  git remote add upstream https://github.com/qmk/qmk_firmware.git

  # throws an error
  git rm --cached lib/ugfx &>/dev/null
  git submodule update --init --recursive

  # Flashing for bootloader: caterina
  # Waiting for USB serial port - reset your controller now (Ctrl+C to cancel)....
  # Device /dev/tty.usbmodem11324401 has appeared; assuming it is the controller.
  # Waiting for /dev/tty.usbmodem11324401 to become writable.
  # Error: programmer type pickit5_updi not found [/opt/homebrew/etc/avrdude.conf:2660]
  # Error: unable to process system wide configuration file /opt/homebrew/etc/avrdude.conf
  # gmake: *** [platforms/avr/flash.mk:173: flash] Error 1
  rm /opt/homebrew/etc/avrdude.conf
  brew reinstall avrdude

  # fixes an issue with missing arm-none-eabi-size binary.
  brew reinstall arm-none-eabi-gcc
  # Run after installiing arm-none-eabi-gcc to confirm all is good.
  #   which arm-none-eabi-size
  #   ls /opt/homebrew/bin/arm-none-eabi-size

  # export PATH for QMK-installed dependencies needed by QMK setup
  export PATH="/opt/homebrew/opt/avr-gcc@8/bin:$PATH"
  export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"

  # -H sets the QMK Home folder since by default it is ~/qmk_firmware
  qmk setup -H ~/dev/qmk_firmware

  # override local python version used by the author of keymapviz
  asdf set python latest

  # install keymapviz to generate keymap layout comments
  # pip install keymapviz

  # compile from anywhere (no need to cd into qml_firmware folder)
  export QMK_HOME=~/dev/qmk_firmware

  # set default keyboard and keymap so that `qmk compile` and `qmk flash`
  # work without additional arguments
  qmk config user.keymap=plam4u user.keyboard=handwired/dactyl_manuform/5x6
)
# Getting Started
# https://docs.qmk.fm/newbs_getting_started
