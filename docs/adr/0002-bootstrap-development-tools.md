# 0002: Bootstrap development tools from their repositories

## Context

The workstation uses Codex, Claude Code, Imoten, Naru, Teio, Yeon, Evolve, Archify, Ripwire, and Ponytail. Several commands and skills were installed as local links. A new workstation could apply the dotfiles and still miss most of this toolchain.

The personal tools already use Git repositories. Their working trees can contain active development changes. Chezmoi must not copy or overwrite those trees.

Naru and Teio also keep live runtime state. That state is machine-local and is not safe to merge through Git.

## Decision

Keep one repository manifest in `~/.config/dev-repos.tsv`. Each entry stores a home-relative checkout path. The `@chezmoi` entry resolves to the active Chezmoi source directory, so the bootstrap repository follows the same sync rules as the tool repositories.

Chezmoi clones a listed repository only when its target path is absent. It never pulls or overwrites an existing working tree. It links commands and skills to those working trees and installs the required Codex plugins.

Chezmoi writes one create-only Claude policy and links Codex to that file when no Codex policy exists. This gives Naru one managed block. Chezmoi also writes Ponytail's off-by-default setting and an empty create-only Teio config. The empty Teio config prevents a new DeepSeek workstation from creating Teio's GPT-specific default preset.

Use `dev-sync pull` and `dev-sync push` for explicit Git synchronization. Both commands preflight every applicable repository and stop before any Git operation when tracked files have changes. Untracked generated files do not block the run. Git still refuses an untracked-file collision during pull. A successful pull applies the updated Chezmoi source. Read-only upstream repositories are never pushed.

Use `dev-sync refresh` after a pull to rebuild the Imoten, Naru, and Ponytail plugin caches. Run it outside Codex, then restart Codex. An open thread can still reference the removed cache path.

Install Ripwire from its checksum-verified `v0.5.0` release. Install Ponytail through the Codex plugin marketplace.

Keep API keys, Naru databases, Teio state, and Git credentials outside Chezmoi and Git.

## Reason

Git remains the one source of truth for active code. Chezmoi owns machine bootstrap only. This prevents a dotfiles apply from replacing uncommitted work or merging live databases.
