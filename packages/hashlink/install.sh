#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "ERROR: failed at line $LINENO: $BASH_COMMAND"' ERR

softwareupdate --install-rosetta --agree-to-license || true

# Pre-warm sudo so later commands do not block.
sudo -v

# Install Intel Homebrew for x86_64 HashLink builds.
if [ ! -x /usr/local/bin/brew ]; then
  arch -x86_64 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

(
  mkdir -p assets

  if [ ! -d assets/hashlink ]; then
    git clone git@github.com:HaxeFoundation/hashlink.git assets/hashlink
  fi

  cd assets/hashlink

  cat >/tmp/hashlink-x86-build.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "ERROR: failed inside x86_64 shell at line $LINENO: $BASH_COMMAND"' ERR

eval "$(/usr/local/bin/brew shellenv)"

make clean || true

/usr/local/bin/brew bundle </dev/null

BREW_PREFIX=/usr/local \
BREW_OPENAL_PREFIX=/usr/local/opt/openal-soft \
make

sudo make codesign_osx
sudo make install
EOF

  chmod +x /tmp/hashlink-x86-build.sh
  trap 'rm -f /tmp/hashlink-x86-build.sh' EXIT

  arch -x86_64 /bin/bash /tmp/hashlink-x86-build.sh
)
# restore ARM brew
eval $(/opt/homebrew/bin/brew shellenv)
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Running 'brew install hashlink' generates the Caveat below:
#   The HashLink/JIT virtual machine (hl) is not installed as only
#   HashLink/C native compilation is supported on ARM processors.
#   See: https://github.com/HaxeFoundation/hashlink/issues/557
