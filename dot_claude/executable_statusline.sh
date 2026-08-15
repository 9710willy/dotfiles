#!/bin/bash
# Claude Code status line.
# Runs on every render, so it stays to one jq process and at most two cheap git
# calls. git is fast here because core.fsmonitor and core.untrackedCache are on.

# IFS must be a literal tab: model names contain spaces ("Opus 5"), so default
# word splitting would shift every field.
IFS=$'\t' read -r MODEL DIR STYLE REMAIN COST ADDED REMOVED VIMMODE < <(
  jq -r '[
    (.model.display_name // "?"),
    (.workspace.current_dir // "."),
    (.output_style.name // "default"),
    ((.context_window.remaining_percentage // 0) | floor),
    ((.cost.total_cost_usd // 0) * 100 | floor),
    (.cost.total_lines_added // 0),
    (.cost.total_lines_removed // 0),
    (.vim.mode // "")
  ] | @tsv' 2>/dev/null
)
[[ -z $MODEL ]] && exit 0

C_MODEL=$'\033[96m' # cyan
C_DIR=$'\033[93m'   # yellow
C_OK=$'\033[92m'    # green
C_WARN=$'\033[93m'  # yellow
C_BAD=$'\033[91m'   # red
C_META=$'\033[95m'  # magenta
C_DIM=$'\033[90m'   # grey
R=$'\033[0m'

# --- git: branch, dirty flag, upstream drift ---
# One porcelain=v2 call yields branch, ahead/behind and dirty state together.
# Three separate git calls cost ~54ms on macOS (process spawn dominates); this
# is ~36ms. --untracked-files=no skips the expensive full-worktree scan.
GIT=""
branch="" ahead=0 behind=0 dirty=0
while read -r f1 f2 rest; do
  case "$f1$f2" in
    '#branch.head') branch=$rest ;;
    '#branch.ab')
      ahead=${rest%% *}  # "+3 -0" -> "+3"
      behind=${rest##* } # "+3 -0" -> "-0"
      ahead=${ahead#+}
      behind=${behind#-}
      ;;
    *) [[ $f1 == 1 || $f1 == 2 || $f1 == u ]] && dirty=1 ;;
  esac
done < <(git status --porcelain=v2 --branch --untracked-files=no 2>/dev/null)

if [[ -n $branch ]]; then
  [[ $branch == '(detached)' ]] && branch=detached
  if ((dirty)); then
    GIT=" ${C_DIM}|${R} ${C_BAD}${branch} ✗${R}"
  else
    GIT=" ${C_DIM}|${R} ${C_OK}${branch} ✓${R}"
  fi
  ((ahead > 0)) && GIT+=" ${C_META}↑${ahead}${R}"
  ((behind > 0)) && GIT+=" ${C_WARN}↓${behind}${R}"
fi

# --- context window: colour by pressure, not just a number ---
if ((REMAIN <= 15)); then
  C_CTX=$C_BAD
elif ((REMAIN <= 35)); then
  C_CTX=$C_WARN
else
  C_CTX=$C_OK
fi

# --- churn this session ---
CHURN=""
if ((ADDED > 0 || REMOVED > 0)); then
  CHURN=" ${C_DIM}|${R} ${C_OK}+${ADDED}${R}/${C_BAD}-${REMOVED}${R}"
fi

# --- cost, tracked in cents to avoid floating point in the shell ---
COSTS=""
((COST > 0)) && COSTS=$(printf " ${C_DIM}| \$%d.%02d${R}" $((COST / 100)) $((COST % 100)))

# --- non-default output style is worth seeing ---
STYLES=""
[[ $STYLE != "default" && -n $STYLE ]] && STYLES=" ${C_DIM}| ${STYLE}${R}"

# --- vim mode (settings.json sets hideVimModeIndicator so this is the only one) ---
VIMS=""
case $VIMMODE in
  INSERT) VIMS=" ${C_OK}[I]${R}" ;;
  NORMAL) VIMS=" ${C_META}[N]${R}" ;;
  VISUAL) VIMS=" ${C_WARN}[V]${R}" ;;
esac

printf '%s[%s]%s %s%s%s%s%s%s %s|%s %s%s%%%s%s%s\n' \
  "$C_MODEL" "$MODEL" "$R" \
  "$C_DIR" "${DIR##*/}" "$R" \
  "$GIT" "$CHURN" "$COSTS" \
  "$C_DIM" "$R" \
  "$C_CTX" "$REMAIN" "$R" \
  "$STYLES" "$VIMS"
