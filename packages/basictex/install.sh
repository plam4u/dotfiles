#!/usr/bin/env bash

brew install basictex

# update the latex package manager
tlmgr update --self

# install latex packages Bebus used for her thesis:
# - pgfornament: for decorative symbols
# - suinitx: for SI units
# - scrhack: to fix some issues with koma-script
# - koma-script: a versatile document class
# - latexmk: a build tool for LaTeX documents
# - biber: a bibliography processor
sudo tlmgr install pgfornament siunitx scrhack koma-script latexmk biber biblatex-apa nth

# install recommended latex packages to avoid hunting them later.
sudo tlmgr install collection-latexrecommended collection-latexextra collection-pictures collection-fontsrecommended

# refresh filename db and font maps
sudo mktexlsr
sudo updmap-sys

# Preview PDFs using Skim app. Run the command below to install it:
# pm i skim
