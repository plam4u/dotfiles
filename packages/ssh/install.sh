#!/usr/bin/env bash

[ ! -f ~/.ssh ] && mkdir -p ~/.ssh/

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m' # No Color

create_private_key() {
    local input_lowercased="$(echo $1 | tr \"[:upper:]\" \"[:lower:]\")"
    echo
    echo -ne "Copy ${GREEN}$1${NC}'s private key to clipboard. Press Enter to continue..."
    read

    pbpaste > ~/.ssh/id_$input_lowercased
    chmod 600 ~/.ssh/id_$input_lowercased
    echo "Created ~/.ssh/id_$input_lowercased private key."

    ssh-keygen -y -f ~/.ssh/id_$input_lowercased > ~/.ssh/id_$input_lowercased.pub
    chmod 644 ~/.ssh/id_$input_lowercased.pub
    echo "Generated ~/.ssh/id_$input_lowercased.pub public key."
}

create_private_key "GitHub"
create_private_key "Bitbucket"
create_private_key "Bebus"

echo
echo "Add a passphrase for extra security:"
echo ">> ssh-keygen -p -f ~/.ssh/id_github"
echo -e "${YELLOW}Info:${NC} ~/.ssh/config sets ${GREEN}\"AddKeysToAgent yes\"${NC} and ${GREEN}\"UseKeychain yes\"${NC}"
echo
