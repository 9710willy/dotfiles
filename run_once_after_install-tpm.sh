#!/bin/bash
# Install tmux plugins after chezmoi creates TPM from .chezmoiexternal.toml.
set -eu

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -x "$TPM_DIR/bin/install_plugins" ]; then
	echo "TPM is missing: $TPM_DIR" >&2
	exit 1
fi

"$TPM_DIR/bin/install_plugins"
