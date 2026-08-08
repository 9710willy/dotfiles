#!/bin/bash
# Install tpm and all tmux plugins on a fresh machine.
# chezmoi runs this once per machine, after files are applied.
set -eu

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
	git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
	"$TPM_DIR/bin/install_plugins"
fi
