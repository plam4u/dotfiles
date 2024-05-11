# .dotfiles

## Clone "dotfiles" folder

Run the command below to install:
- Homebrew (brew)
- Command Line Tools (CLT)
- clone dotfiles at ~/.dotfiles
```
bash -c "`curl -fsSL https://raw.githubusercontent.com/plam4u/dotfiles/main/remote-install.sh`"
```

## Install apps

Run the command below to install the apps specified in ~/.dotfiles/Brewfile
```
brew bundle install --file=~/.dotfiles/Brewfile
```
