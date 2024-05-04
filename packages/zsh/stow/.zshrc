# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# export homebrew variables for current script
eval $(/opt/homebrew/bin/brew shellenv)

# dotfiles
export DOTFILES_DIR="$HOME/dotfiles"
export PATH="$DOTFILES_DIR/bin:$PATH"

# editor
export VISUAL=vim
export EDITOR="$VISUAL"

# prefer US English and use UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# source app-specific .zshrc's
ZSHRC_DIR="$HOME/.zshrc.d"
if [ -d "$ZSHRC_DIR" ]; then
  for SCRIPT in "$ZSHRC_DIR"/*.sh; do
    [ -f "$SCRIPT" ] && . "$SCRIPT"
  done
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
