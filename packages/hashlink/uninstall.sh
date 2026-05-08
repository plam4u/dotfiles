#!/usr/bin/env bash

rm -f /usr/local/bin/hl /usr/local/lib/libhl.dylib /usr/local/lib/*.hdll
rm -f /usr/local/include/hl.h /usr/local/include/hl_ffi.h /usr/local/include/hlc.h /usr/local/include/hlc_main.c
sudo arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
