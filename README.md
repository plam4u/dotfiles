# .dotfiles

## Clone "dotfiles" folder

Run the command below to install:
- Homebrew (brew)
- Command Line Tools (CLT)
- clone dotfiles into ~/dotfiles
```
bash -c "`curl -fsSL https://raw.githubusercontent.com/plam4u/dotfiles/main/remote-install.sh`"
```

## Install apps

Required:
Terminal needs disk access to execute some of the commands:

`System Settings` > `Privacy and Security` > `Full Disk Access` > `Terminal`

Run the command below to start the setup:
```
cd ~/dotfiles && ./bootstrap.sh
```

## Interesting bundles

- bootstrap: essential apps and configs
- devices: drivers for my current setup
- terminal-iterm: setup my preferred terminal
- messaging: WhatsApp, Telegram, Messenger
- multimedia: audio, video, and image processing
- other packages can be installed on demand depending on the context
