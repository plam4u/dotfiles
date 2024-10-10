#!/bin/bash

# Prevent the script from being sourced multiple times
if [ "${SHARED_FUNCTIONS_SOURCED:-}" ]; then
  return
fi
SHARED_FUNCTIONS_SOURCED=1

abs_path() {
  if [ -d $1 ]; then
    echo "$(cd $1 && pwd)"
  else
    echo "$(cd $(dirname $1) && pwd)"
  fi
}

bundle_path() {
  local input_path="$1"
  if [[ "$input_path" == bundles/* ]]; then
    echo "$input_path" # Return as is
  else
    echo "bundles/$input_path" # Prepend "bundles/"
  fi
}

map_packages() {
  func_ref=$1
  shift

  # navigate to dotfiles' root
  DIR="$(abs_path $0)/.."
  cd "$DIR"

  local packages=()
  local bundles=()

  while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
    case $1 in
    -b | --bundle)
      shift
      bundles+=("$(bundle_path "$1")")
      ;;
    -d | --dir)
      shift
      DIR=$(abs_path "$1")
      cd "$DIR"
      ;;
    -f | --force)
      FORCE=1
      ;;
    esac
    shift
  done

  # --bundle <bundle-name>
  for bundle in "${bundles[@]}"; do
    if [[ ! -f "$bundle" ]] &>/dev/null; then
      echo "Error: File '$bundle' not found."
      exit 1
    else
      while IFS= read -r package; do
        if [[ "$package" =~ ^# || "$package" == "" ]]; then
          continue
        fi
        packages+=("$package")
      done <"$bundle"
    fi
  done

  # positional args
  for package in "$@"; do
    if [[ ! $package =~ ^- ]]; then
      packages+=("$package")
    fi
  done

  for package in "${packages[@]}"; do
    echo
    "$func_ref" $package
  done

  echo
  echo "$(basename $0) finished successfully!"
  echo
}

###############################################################################
# Copied from my previous dotfiles
###############################################################################

rebaseCurrentOntoLatestDevelop() {
  CUR_BRANCH=$(git branch --show-current)
  git checkout develop
  git fetch --all --prune
  git pull
  git checkout "$CUR_BRANCH"
  git rebase develop
}

function gitListObjectBySize() {
  local tempFile=$(mktemp)

  # work over each commit and append all files in tree to $tempFile
  local IFS=$'\n'
  local commitSHA1
  for commitSHA1 in $(git rev-list --all); do
    git ls-tree -r --long "$commitSHA1" >>"$tempFile"
  done

  # sort files by SHA-1, de-dupe list and finally re-sort by filesize
  sort --key 3 "$tempFile" |
    uniq |
    sort --key 4 --numeric-sort --reverse

  # remove temp file
  rm "$tempFile"
}

gitWorkTreeAdd() {
  BRANCH_NAME=$1
  PATH_NAME=$1

  echo "> git fetch --all --prune"
  git fetch --all --prune
  echo

  echo "> git worktree add --track -b $BRANCH_NAME $PATH_NAME origin/$BRANCH_NAME"
  git worktree add --track -b "$BRANCH_NAME" "$PATH_NAME" origin/"$BRANCH_NAME"

  echo "$BRANCH_NAME/" >>.git/info/exclude

  echo "pushd $BRANCH_NAME"
  pushd "$BRANCH_NAME"
  echo

  # Now managed by asdf
  # echo "> pyenv local 2.7.18"
  # pyenv local 2.7.18
  # echo
}

gitWorkTreeRemove() {
  if [ $# -eq 0 ]; then
    BRANCH_NAME=$(git branch --show-current)
  else
    BRANCH_NAME=$1
  fi

  git stash push
  # git pull
  # git push
  popd
  git worktree remove "$BRANCH_NAME"
  git branch -D "$BRANCH_NAME"
  git clean -fdx
}

runCrontabNow() {
  echo 'Syncing vimwiki...'
  ~/.dotfiles/scripts/vimwiki_sync.sh
  echo 'Syncing vimwiki DONE!'

  echo 'Syncing tasks...'
  ~/.dotfiles/scripts/tasks_sync.sh
  echo 'Syncing tasks DONE!'
}

gitAddAndCommitAll() {
  echo "> git add --all"
  git add --all
  echo "> git commit -m \"$1\""
  git commit -m "$1"
  echo
  echo "> git pull"
  git pull
  echo
  echo "> git push"
  git push
}

inGit() {
  if [ -d .git ]; then
    echo .git
  else
    git rev-parse --git-dir 2>/dev/null
  fi
}

copyCurrentBranch() {
  echo $(git branch --show-current)
}

copyJiraTicketForCurrentBranch() {
  ticket=$(git branch --show-current | sed 's/\(IOS-[0-9]*\).*/\1/')
  echo "$ticket"
}

openJiraTicketForCurrentBranch() {
  TICKET=$(copyJiraTicketForCurrentBranch)
  URL="https://example.com/browse/$TICKET"
  echo "Opening $URL"
  open "$URL"
}

copyLastCommitHash() {
  git log --oneline --no-abbrev | head -1 | awk '{ print $1 }' | pbcopy
}

gitStatusAndGitDiff() {
  git status
  git diff
}
