#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // 0' | cut -d. -f1)

# Colors (bright variants for visibility when dimmed)
CYAN='\033[96m'
YELLOW='\033[93m'
GREEN='\033[92m'
RED='\033[91m'
MAGENTA='\033[95m'
RESET='\033[0m'

# Git branch with clean/dirty indicator
GIT_INFO=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            GIT_INFO=$(printf " | \033[92m%s ✓\033[0m" "$BRANCH")
        else
            GIT_INFO=$(printf " | \033[91m%s ✗\033[0m" "$BRANCH")
        fi
    fi
fi

printf "\033[96m[%s]\033[0m \033[93m%s\033[0m%s | \033[95m%s%%\033[0m\n" "$MODEL" "$(basename "$CURRENT_DIR")" "$GIT_INFO" "$REMAINING"
