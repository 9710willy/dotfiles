#!/bin/bash
set -euo pipefail

render() {
    chezmoi execute-template --override-data "$1" --file "$2"
}

copilot='{"machine":{"context":"company"},"codex":{"provider":"copilot"}}'
deepseek='{"machine":{"context":"personal"},"codex":{"provider":"deepseek"}}'

copilot_brew=$(render "$copilot" Brewfile.tmpl)
deepseek_brew=$(render "$deepseek" Brewfile.tmpl)

if grep -qx 'brew "tree"' <<<"$copilot_brew"; then
    echo 'tree must not be installed' >&2
    exit 1
fi
grep -qx 'brew "sleepwatcher"' <<<"$copilot_brew"
if grep -qx 'brew "sleepwatcher"' <<<"$deepseek_brew"; then
    echo 'DeepSeek must not install SleepWatcher' >&2
    exit 1
fi

copilot_hook=$(render "$copilot" run_onchange_after_brew-bundle.sh.tmpl)
deepseek_hook=$(render "$deepseek" run_onchange_after_brew-bundle.sh.tmpl)

grep -qx 'env -u TMUX brew services restart sleepwatcher' <<<"$copilot_hook"
if grep -q 'sleepwatcher' <<<"$deepseek_hook"; then
    echo 'DeepSeek must not start SleepWatcher' >&2
    exit 1
fi
/bin/bash -n <<<"$copilot_hook"
/bin/bash -n <<<"$deepseek_hook"

echo "provider package behavior passed"
