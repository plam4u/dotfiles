# Installation steps

1. exists package dir
    yes -> exec `install_package_steps` below
    no  -> exec `brew install $package` only
2. install_package_steps
    1. run `install.sh` or `brew install $package`
    2. run `stow` using the "stow" dir
    3. run scripts inside `macos-defaults` dir
    4. run scripts inside `scripts` dir
