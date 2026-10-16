setopt autocd

alias ..="\cd .."
alias ...="\cd ../.."
alias ....="\cd ../../.."
alias .....="\cd ../../../.."
alias ......="\cd ../../../../.."
alias /="\cd /"
alias ~="\cd ~"
alias -- -="cd -"

alias d=date

# Alt-Z to foreground
bindkey -s '^[z' 'fg\n'
