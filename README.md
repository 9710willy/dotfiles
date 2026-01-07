# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Setup

```bash
# One-liner for new Mac (will prompt for machine context)
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
- **Git** - Identity templated (company vs personal)
- **mise** - Universal version manager (Node, Python, etc.)

## Machine Context

On first init, you'll be prompted for machine context:

- `company` - Work machine (prompts for git name/email/GPG key)
- `personal` - Personal machine (uses GitHub noreply email)

### Company Machine Setup

When prompted, enter:
- **Machine context**: `company`
- **Git name**: Your work name
- **Git email**: your.email@company.com
- **GPG signing key**: Your key ID (from `gpg --list-secret-keys`) or `none`

### Personal Machine Setup

When prompted, enter:
- **Machine context**: `personal`

That's it! Personal machines use GitHub's noreply email automatically.

### Changing Context Later

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.machine]
    context = "company"  # or "personal"

[data.git]
    name = "Your Name"
    email = "your@email.com"
    signingKey = "KEY_ID"  # or "none"
```

Then run `chezmoi apply`.

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
4. Setup fzf key bindings

## Files

| Source | Target |
|--------|--------|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `Brewfile.tmpl` | `~/Brewfile` |
| `dotfiles/nvim/` | `~/dotfiles/nvim/` → `~/.config/nvim/` |

## Architecture

```
~/.config/chezmoi/chezmoi.toml  # Local config (secrets, not committed)
    ↓
~/.local/share/chezmoi/         # Source of truth (committed)
    ├── .chezmoi.toml.tmpl      # Config template (prompts on init)
    ├── Brewfile.tmpl           # Context-aware packages
    ├── dot_gitconfig.tmpl      # Context-aware git identity
    └── dot_zshrc.tmpl          # Shell config
```
