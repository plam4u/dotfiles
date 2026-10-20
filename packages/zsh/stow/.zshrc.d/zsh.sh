setopt autocd

alias ..="\cd .."
alias ...="\cd ../.."
alias ....="\cd ../../.."
alias .....="\cd ../../../.."
alias ......="\cd ../../../../.."
alias /="\cd /"
alias ~="\cd ~"
alias -- -="cd -"
alias soz="source ~/.zshrc"

alias d=date

# Alt-Z to foreground
bindkey -s '^[z' 'fg\n'
