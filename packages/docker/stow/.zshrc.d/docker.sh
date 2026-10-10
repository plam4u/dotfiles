# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/plam/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions

# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/plam/.docker/bin"
# End of Docker Desktop section.

