#!/usr/bin/env bash

(
  mkdir -p assets
  cd assets
  git clone git@github.com:deepnight/gameBase.git
  cd gameBase
  haxe setup.hxml
)
