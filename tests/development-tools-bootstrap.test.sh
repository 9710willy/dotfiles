#!/bin/bash

set -euo pipefail

root=$(mktemp -d "${TMPDIR:-/tmp}/development-tools-test.XXXXXX")
trap 'rm -rf "$root"' EXIT

home_dir="$root/home"
bin_dir="$root/bin"
mkdir -p "$home_dir/.config" "$home_dir/.local/bin" "$home_dir/.codex/skills" \
    "$home_dir/.claude/skills/atlassian-curl" "$home_dir/bin" "$bin_dir"

cp dot_config/dev-repos.tsv "$home_dir/.config/dev-repos.tsv"
printf '%s\n' old > "$home_dir/.local/bin/naru"
printf '%s\n' '{}' > "$home_dir/.claude/settings.json"
printf '%s\n' skill > "$home_dir/.claude/skills/atlassian-curl/SKILL.md"

for repo_path in \
    work/pstack \
    work/naru \
    work/teio-tui \
    work/yeon \
    stuff/evolve \
    stuff/deepseek-harness \
    work/archify; do
    mkdir -p "$home_dir/$repo_path/.git"
done

mkdir -p \
    "$home_dir/work/pstack/skills/poteto-mode/scripts/node_modules" \
    "$home_dir/work/pstack/skills/poteto-mode/references" \
    "$home_dir/work/pstack/skills/no-comments/references" \
    "$home_dir/work/pstack/templates/codex-agents" \
    "$home_dir/work/naru/codex" \
    "$home_dir/work/yeon/bin" \
    "$home_dir/work/yeon/skills/yeon" \
    "$home_dir/stuff/evolve/skills/evolve" \
    "$home_dir/work/archify/archify/bin" \
    "$home_dir/work/archify/archify/node_modules"

touch \
    "$home_dir/work/naru/naru.py" \
    "$home_dir/work/teio-tui/teio.mjs" \
    "$home_dir/work/yeon/bin/yeon.mjs" \
    "$home_dir/work/yeon/skills/yeon/SKILL.md" \
    "$home_dir/stuff/evolve/skills/evolve/SKILL.md" \
    "$home_dir/work/archify/archify/bin/archify.mjs" \
    "$home_dir/work/archify/archify/SKILL.md"

cat > "$home_dir/work/pstack/templates/codex-agents/imoten-poteto-agent.toml" <<'EOF'
name = "imoten-poteto-agent"
{{MODEL_CONFIG}}
developer_instructions = """
{{PROMPT}}
"""
EOF
cat > "$home_dir/work/pstack/templates/codex-agents/imoten-comment-sicko.toml" <<'EOF'
name = "imoten-comment-sicko"
sandbox_mode = "read-only"
{{MODEL_CONFIG}}
developer_instructions = """
{{PROMPT}}
"""
EOF
printf '%s\n' 'Poteto prompt.' > "$home_dir/work/pstack/skills/poteto-mode/references/poteto-agent-prompt.md"
printf '%s\n' 'Comment prompt.' > "$home_dir/work/pstack/skills/no-comments/references/comment-sicko-prompt.md"

cat > "$bin_dir/gh" <<'EOF'
#!/bin/bash
[[ "$1 $2" == "auth status" ]]
EOF

cat > "$bin_dir/codex" <<'EOF'
#!/bin/bash
case "$1 $2 $3" in
    "plugin marketplace list") printf '%s\n' '{"marketplaces":[]}' ;;
    "plugin list --json") printf '%s\n' '{"installed":[]}' ;;
    *) printf 'codex %s\n' "$*" >> "$COMMAND_LOG" ;;
esac
EOF

cat > "$bin_dir/claude" <<'EOF'
#!/bin/bash
case "$1 $2 $3" in
    "plugin marketplace list") printf '%s\n' '[]' ;;
    "plugin list --json") printf '%s\n' '[]' ;;
    *) printf 'claude %s\n' "$*" >> "$COMMAND_LOG" ;;
esac
EOF

cat > "$bin_dir/ripwire" <<'EOF'
#!/bin/bash
printf '%s\n' 'ripwire 0.5.0 (test)'
EOF

cat > "$bin_dir/mise" <<'EOF'
#!/bin/bash
exit 0
EOF

cat > "$home_dir/bin/update-deepseek-catalog" <<'EOF'
#!/bin/bash
touch "$HOME/.codex/models.json"
EOF

for command_name in gh codex claude ripwire mise; do
    chmod +x "$bin_dir/$command_name"
done
chmod +x "$home_dir/bin/update-deepseek-catalog"

chezmoi execute-template \
    --override-data '{"codex":{"provider":"deepseek"},"machine":{"context":"personal"}}' \
    -f run_onchange_after_install-development-tools.sh.tmpl \
    > "$root/install-development-tools.sh"

test_path="$bin_dir:/opt/homebrew/bin:/usr/bin:/bin"
COMMAND_LOG="$root/commands.log" HOME="$home_dir" PATH="$test_path" \
    /bin/bash "$root/install-development-tools.sh" >/dev/null
COMMAND_LOG="$root/commands.log" HOME="$home_dir" PATH="$test_path" \
    /bin/bash "$root/install-development-tools.sh" >/dev/null

[[ "$(readlink "$home_dir/.local/bin/naru")" == "$home_dir/work/naru/naru.py" ]]
[[ "$(readlink "$home_dir/.local/bin/teio")" == "$home_dir/work/teio-tui/teio.mjs" ]]
[[ "$(readlink "$home_dir/.codex/skills/evolve/SKILL.md")" == "$home_dir/stuff/evolve/skills/evolve/SKILL.md" ]]
[[ -f "$home_dir/.local/bin/naru.before-dev-sync" ]]
grep -q '^model = "deepseek-flash"$' "$home_dir/.codex/agents/imoten-poteto-agent.toml"
grep -q '^model_reasoning_effort = "high"$' "$home_dir/.codex/agents/imoten-comment-sicko.toml"

jq -e --arg command "python3 $home_dir/work/naru/hook_spill.py" '
    [.hooks.PostToolUse[]? |
        select(.matcher == "Bash|Read" and any(.hooks[]?; .command == $command))] |
    length == 1
' "$home_dir/.claude/settings.json" >/dev/null

grep -q 'codex plugin add imoten@imoten-local' "$root/commands.log"
grep -q 'codex plugin add naru-codex@naru' "$root/commands.log"
grep -q 'claude plugin install imoten@willee-imoten --scope user --yes' "$root/commands.log"
grep -q 'claude plugin install evolve@evolve --scope user --yes' "$root/commands.log"

echo "development tool bootstrap passed"
