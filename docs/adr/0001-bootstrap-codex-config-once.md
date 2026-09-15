# 0001: Bootstrap Codex files once

## Context

Chezmoi previously managed all of `~/.codex/config.toml`. Codex and Imoten also write plugin, marketplace, hook, and generated model settings to this file. A later `chezmoi apply` could remove those runtime-owned settings.

Direct DeepSeek also needs an Imoten role map. Imoten now verifies direct DeepSeek and owns its optional agent profiles.

## Decision

Create `~/.codex/config.toml` from the selected provider template only when the file is missing. After creation, Codex and Imoten own changes to the file.

For DeepSeek, create `~/.codex/imoten-models.md` only when the file is missing. Assign `deepseek-flash` at `high` effort to each role. `update-deepseek-catalog` extracts the current `~/.codex/models.json` catalog from DeepSeek's official Codex setup script without copying the API key into `config.toml`. Initial setup and `dotfiles-update` call that command.

Do not write agent profiles from Chezmoi. After the API key is available, `$setup-pstack install agents` verifies the provider, replaces the bootstrap role map with a proved map, and owns the profiles through its receipt. For Copilot, leave both the role map and profiles to `$setup-pstack`.

## Reason

This gives the initial setup one portable source without creating two writers for the same settings. Imoten owns generated profiles and their receipt. Chezmoi preserves local plugin and model state on later runs.
