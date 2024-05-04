# .dotfiles

## Clone "dotfiles" folder

Run the command below to install:
- brew
- Command Line Tools for Xcode
- dotfiles at $HOME/.dotfiles
```
bash -c "`curl -fsSL https://raw.githubusercontent.com/plam4u/dotfiles/master/remote-install.sh`"
```

## Install apps

Run the command below to install the apps specified in ~/.dotfiles/Brewfile
```brew bundle install --file=~/.dotfiles/Brewfile```
