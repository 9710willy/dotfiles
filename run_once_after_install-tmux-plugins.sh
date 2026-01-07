#!/bin/bash

# TPM is cloned via .chezmoiexternal.toml
# Plugins install on first tmux launch with: prefix + I (Ctrl-a + I)

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "TPM installed. Run 'prefix + I' (Ctrl-a + I) in tmux to install plugins."
fi
