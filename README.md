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
- **Git** - Identity templated (work vs personal)

## Work Machine Setup

For work machines, create `~/.config/chezmoi/chezmoi.toml`:

```toml
# Chezmoi configuration

[git]
    autoCommit = true

[data]
    # Set to true on work machines
    isWorkMachine = true

    # Work git config (required for work machines)
    workGitName = "Your Name"
    workGitEmail = "your.email@company.com"
    workGitSigningKey = "YOUR_GPG_KEY_ID"  # From: gpg --list-secret-keys
```

This configures:
- Git identity with work email
- GPG commit signing
- Auto-commit for chezmoi changes

**Personal machines**: Just set `isWorkMachine = false` (or omit the file entirely).

## Version Managers

This setup uses **mise** (not nvm/pyenv) for Node.js, Python, etc.

```bash
# Global defaults (in ~/.config/mise/config.toml)
mise use --global node@20 python@3.12

# Per-project (creates mise.toml in project dir)
mise use node@18
```

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
