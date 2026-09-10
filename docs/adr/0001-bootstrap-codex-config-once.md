# 0001: Bootstrap Codex files once

## Context

Chezmoi previously managed all of `~/.codex/config.toml`. Codex and Imoten also write plugin, marketplace, hook, and generated model settings to this file. A later `chezmoi apply` could remove those runtime-owned settings.

Direct DeepSeek also needs an Imoten role map. The bundled `$setup-pstack` command cannot create it because that command reads its model catalog from `copilot-api`.

## Decision

Create `~/.codex/config.toml` from the selected provider template only when the file is missing. After creation, Codex and Imoten own changes to the file.

For DeepSeek, create `~/.codex/imoten-models.md` only when the file is missing. Assign `deepseek-flash` at `high` effort to each role. For Copilot, leave the role map to `$setup-pstack`.

## Reason

This gives the initial setup one portable source without creating two writers for the same settings. It also preserves local plugin and model state on later chezmoi runs.
