# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Setup

```bash
# One-liner for new Mac
chezmoi init --apply 9710willy/dotfiles
```

Or step by step:
```bash
chezmoi init https://github.com/9710willy/dotfiles.git
chezmoi diff   # Preview changes
chezmoi apply  # Apply changes
```

## What's Included

- **Neovim** - Full LSP config, completion, telescope, etc.
- **Tmux** - With vim-tmux-navigator integration
- **Zsh** - Powerlevel10k prompt, syntax highlighting, autosuggestions
- **Git** - GPG signing configured

## Bootstrap Scripts

On first run, chezmoi will automatically:

1. Install Homebrew (if missing)
2. Install packages via `brew bundle` (neovim, tmux, LSPs, etc.)
3. Clone zsh plugins (powerlevel10k, fast-syntax-highlighting, etc.)

## Files

| Source | Target |
|--------|--------|
| `dot_zshrc` | `~/.zshrc` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_gitconfig` | `~/.gitconfig` |
| `dotfiles/nvim/` | `~/.config/nvim/` |
