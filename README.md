# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

See [Set up the other Mac](docs/other-workstation-setup.md) for the DeepSeek workstation procedure.

## Quick Setup

```bash
# Chezmoi is already installed. This prompts for machine context and Codex provider.
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
- **Zsh** - Native prompt, syntax highlighting, autosuggestions
- **Git** - Identity templated (company vs personal)
- **mise** - Universal version manager (Node, Python, etc.)
- **Development tools** - Codex, Imoten, Naru, Teio, Yeon, Evolve, Archify, Ripwire, and Ponytail

Claude Code is an optional fallback. Chezmoi does not install its runtime or manage its plugins and hooks.

## Machine Context

On first init, you'll be prompted for machine context:

- `company` - Work machine (prompts for git name/email/GPG key)
- `personal` - Personal machine (uses GitHub noreply email)

You also select one Codex provider:

- `copilot` uses a preinstalled local enterprise Copilot proxy on a company machine.
- `deepseek` calls the DeepSeek API directly. It does not install or run `copilot-api`.

## Codex with Copilot

Install `copilot-api` at `~/.local/opt/copilot-api` before you select the
Copilot option. Load its launch agents too. Chezmoi manages the maintenance
scripts, launch agent files, and wake hook. It does not install the proxy
package or load its launch agents.

Run `dotfiles-health` to check the proxy and its services.

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

## Codex with DeepSeek

Select `deepseek` during `chezmoi init`. Chezmoi creates the initial Codex config, then Codex owns later plugin and model entries. Chezmoi installs Codex and the development toolchain. It keeps the API key in the ignored `~/.zshrc.local` file.

```bash
touch ~/.zshrc.local
chmod 600 ~/.zshrc.local
${EDITOR:-vi} ~/.zshrc.local
```

Add this line with your real key:

```bash
export DEEPSEEK_API_KEY='your-key'
```

Start a new shell. Verify the API connection:

```bash
codex exec -m deepseek-flash "Reply with OK."
```

Chezmoi extracts `~/.codex/models.json` from DeepSeek's official Codex setup script. It does not copy the API key into the Codex config.

Chezmoi creates `~/.codex/imoten-models.md` once. All Imoten roles use `deepseek-flash` at `high` effort. Do not run `$setup-pstack` on this workstation. That command currently builds its model catalog from `copilot-api`.

Direct DeepSeek does not provide the multi-vendor review panel available through `copilot-api`. Workflows that require different model vendors stop and report that limit. Other Codex and Imoten workflows use DeepSeek directly.

Run the local checks:

```bash
dotfiles-health
```

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
3. Run one development-workflow setup script
4. Clone the development repositories
5. Link the commands and skills
6. Install Ripwire and the Codex plugins
7. Install the DeepSeek model catalog and Imoten agent profiles

Private repositories require GitHub CLI authentication. On a new workstation, the first apply installs `gh` and can stop at the authentication gate. Run `gh auth login`, then run `chezmoi apply` again.

## Development repository sync

Chezmoi clones missing repositories. It never changes an existing working tree. The same manifest includes the active Chezmoi source repository.

Check every repository:

```bash
dev-sync status
```

Pull clean repositories with fast-forward updates only:

```bash
dev-sync pull
```

Push committed changes from writable repositories:

```bash
dev-sync push
```

`dev-sync` refuses tracked changes. Commit or stash active work first. Untracked generated files do not block synchronization. Git still refuses an untracked-file collision during pull. Naru databases, Teio state, API keys, and Git credentials remain local to each workstation.

On a DeepSeek workstation, Chezmoi creates an empty Teio config. Add a `deepseek-flash` execution preset before the first Teio coordinator or worker run. This avoids Teio's GPT-specific default preset.

## Helper Scripts

```bash
dotfiles-health    # Validate your setup (check for missing tools)
dotfiles-update    # Update chezmoi, Homebrew, and mise
dev-sync           # Show development repository state
dev-sync pull      # Pull clean development repositories
dev-sync push      # Push committed development repositories
dev-sync refresh   # Refresh Codex plugin caches, then restart Codex
update-deepseek-catalog  # Refresh DeepSeek's Codex model catalog
dotfiles-cleanup   # Clean up caches (npm, pip, docker, etc.)
dotfiles-cleanup --dry-run  # See what would be cleaned
macos-update       # Run macOS software updates (with Little Snitch reminder)
```

## Shell Features

### Key Bindings
- `Ctrl+R` - fzf history search
- `Ctrl+T` - fzf file finder
- `Ctrl+G` - fzf git branch switcher with preview
- `Alt+C` - fzf directory jump

### Helper Functions
```bash
mkcd <dir>         # Create directory and cd into it
replace <s> <r> <glob>  # Find and replace in files
git-cleanup        # Delete local branches that are gone from remote
port <num>         # Find what's using a port
serve [port]       # Quick HTTP server (default: 8000)
extract <file>     # Extract any archive format
```

### Modern CLI Aliases
```bash
ls  → eza          # Better ls
ll  → eza -la      # Long list with git status
cat → bat          # Syntax highlighted cat
```

## Files

| Source | Target |
|--------|--------|
| `dot_zshrc` | `~/.zshrc` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `Brewfile.tmpl` | `~/Brewfile` |
| `bin/executable_*` | `~/bin/*` |
| `private_dot_ssh/` | `~/.ssh/` |
| `dotfiles/nvim/` | `~/dotfiles/nvim/` → `~/.config/nvim/` |

## Architecture

```
~/.config/chezmoi/chezmoi.toml  # Local config (secrets, not committed)
    ↓
~/.local/share/chezmoi/         # Source of truth (committed)
    ├── .chezmoi.toml.tmpl      # Config template (prompts on init)
    ├── Brewfile.tmpl           # Context-aware packages
    ├── dot_codex/              # Create-only Codex config and DeepSeek role map
    ├── dot_gitconfig.tmpl      # Context-aware git identity
    └── dot_zshrc               # Shell config
```

Chezmoi creates `~/.codex/config.toml` only when it is missing. For DeepSeek, it also creates `~/.codex/imoten-models.md` only when that file is missing. Codex and Imoten can then update their runtime-owned settings without losing them on the next `chezmoi apply`.
