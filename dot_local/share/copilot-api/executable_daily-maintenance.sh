#!/bin/bash
# Daily maintenance for the copilot-api launchd service.
#
# Runs from com.willee1.copilot-api-restart at 04:00. Three jobs:
#   1. Rotate ~/Library/Logs/copilot-api.log. Nothing else rotates it - the
#      plist appends straight to StandardOutPath and there is no newsyslog.d
#      entry - and the patch/diagnostic log lines make it grow steadily.
#   2. Reapply the local patches if an npm upgrade replaced the server bundle.
#      Without this check the restart below would happily boot an unpatched
#      bundle and the encrypted-content failures would return with no obvious
#      cause.
#   3. Restart the service so the Copilot IDE token is re-minted. The token
#      lives ~30 minutes and the in-process refresh has been seen to stop
#      working on a long-lived process, which 401s every request until restart.
#
# Rotation happens BEFORE the restart on purpose: the service reopens
# StandardOutPath on start, so the truncation cannot race a live writer.
set -euo pipefail

log="$HOME/Library/Logs/copilot-api.log"
service="gui/$(id -u)/com.willee1.copilot-api"
keep=3

if [ -f "$log" ]; then
  for i in $(seq $((keep - 1)) -1 1); do
    [ -f "$log.$i.gz" ] && mv -f "$log.$i.gz" "$log.$((i + 1)).gz"
  done
  cp -p "$log" "$log.1"
  gzip -f "$log.1"
  # Truncate in place rather than delete: the running process holds this fd,
  # and unlinking it would leave it writing to an invisible inode.
  : >"$log"
  echo "$(date '+%Y-%m-%dT%H:%M:%S') rotated log, kept $keep generations"
fi

# Drop rotations beyond the keep count.
for f in "$log".*.gz; do
  [ -f "$f" ] || continue
  n="${f##*.log.}"
  n="${n%%.gz}"
  [ "$n" -gt "$keep" ] 2>/dev/null && rm -f "$f"
done

# Codex disk-reclaim staleness alarm.
#
# WHY THIS LIVES HERE, in the copilot-api job rather than the reclaim job: the
# 2026-08-19 investigation found the reclaim had never succeeded ONCE since it
# was installed on 2026-08-14. The stamp file was simply absent, nothing looked
# at it, and ~/.codex silently reached 9.7GB. A self-check inside reclaim cannot
# catch that, because the failure mode was that reclaim never got to run at all.
# This is a SEPARATE launchd agent on a separate schedule, so it still fires -
# and still complains - when com.willee1.codex-reclaim has stopped firing.
#
# Threshold is 2 days, not 1: the prune is expected daily, so a single missed day
# is noise (a powered-off Mac), while two is a real signal.
prune_stamp="$HOME/.codex/.reclaim-last-prune"
stale_days=2
if [ ! -f "$prune_stamp" ]; then
  echo "$(date '+%Y-%m-%dT%H:%M:%S') WARNING: codex disk reclaim has NEVER succeeded - $prune_stamp is missing."
  echo "  Check: launchctl list | grep codex-reclaim   and   ~/Library/Logs/codex-reclaim.log"
  echo "  ~/.codex is currently $(du -sh "$HOME/.codex" 2>/dev/null | cut -f1 || echo '?')"
else
  last_prune="$(cat "$prune_stamp" 2>/dev/null || true)"
  last_prune_s="$(date -j -f '%Y-%m-%d' "$last_prune" +%s 2>/dev/null || echo 0)"
  if [ "$last_prune_s" -eq 0 ]; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S') WARNING: $prune_stamp is unreadable (contains: '$last_prune')"
  else
    prune_age_days=$((($(date +%s) - last_prune_s) / 86400))
    if [ "$prune_age_days" -gt "$stale_days" ]; then
      echo "$(date '+%Y-%m-%dT%H:%M:%S') WARNING: codex disk reclaim last pruned on $last_prune ($prune_age_days days ago)."
      echo "  Check: launchctl list | grep codex-reclaim   and   ~/Library/Logs/codex-reclaim.log"
      echo "  ~/.codex is currently $(du -sh "$HOME/.codex" 2>/dev/null | cut -f1 || echo '?')"
    fi
  fi
fi

# copilot-api usage-data retention.
#
# copilot-api.sqlite was the only store in this stack with NO maintenance at all:
# 83316 rows / 27MB accumulated between 2026-08-06 and 2026-08-19, i.e. ~2.1MB a
# day, ~770MB a year, growing forever. It holds token_usage_events - the spend
# data behind the model-routing decision recorded in ~/.codex/config.toml - so
# the window is deliberately generous. 180 days keeps far more than the 7-day
# comparisons that analysis actually runs, and bounds the file at roughly 380MB.
# When this was added the cutoff matched 0 rows: it is a ceiling, not a cull.
#
# The proxy holds this db open in WAL mode, so the delete must tolerate a live
# writer: bounded busy timeout, and a lock is a skip-until-tomorrow rather than
# an error. No VACUUM - it would have to win an exclusive lock against the
# running proxy, and freed pages are reused by the next events anyway.
usage_db="$HOME/.local/share/copilot-api/copilot-api.sqlite"
USAGE_KEEP_DAYS="${USAGE_KEEP_DAYS:-180}"
if [ -f "$usage_db" ]; then
  usage_cutoff_ms=$((($(date +%s) - USAGE_KEEP_DAYS * 86400) * 1000))
  if usage_deleted=$(sqlite3 -cmd ".timeout 15000" "$usage_db" \
    "DELETE FROM token_usage_events WHERE created_at_ms < $usage_cutoff_ms; SELECT changes();" 2>/dev/null); then
    case "$usage_deleted" in
      '' | *[!0-9]*)
        echo "$(date '+%Y-%m-%dT%H:%M:%S') usage retention: unexpected sqlite3 output '$usage_deleted' - not retrying"
        ;;
      0) : ;;
      *)
        echo "$(date '+%Y-%m-%dT%H:%M:%S') usage retention: deleted $usage_deleted event(s) older than ${USAGE_KEEP_DAYS}d"
        ;;
    esac
  else
    echo "$(date '+%Y-%m-%dT%H:%M:%S') usage retention: skipped, db busy - retrying tomorrow"
  fi
fi

# Duplicate-codex sweep.
#
# The Claude Code hook (~/.claude/hooks/guard-global-npm.sh) only inspects
# commands Claude runs. A duplicate can still arrive from a shell you typed in,
# a script, an editor terminal, or a tool that re-runs a global install - so this
# catches what the hook structurally cannot see.
#
# Background: ~/work/mise.toml pins node 20, and mise puts node 20's bin first on
# PATH inside that tree, so a global install from there lands in node 20's prefix
# and shadows the Homebrew copy for ~/work only, silently. Measured 2026-08-19:
# 0.147.0 in ~ vs 0.148.0 in ~/work, two ~260MB trees, one day of debugging.
#
# Safety: the sweep only runs when the CANONICAL Homebrew install is present, so
# it can never remove the last remaining copy.
#
# UPDATED 2026-08-21: codex moved from a global npm install to the Homebrew CASK
# (`brew install --cask codex`), so the canonical copy is a binary on PATH, not a
# node_modules directory. Left as the old npm path this guard could never be
# true again and the sweep below would silently never run - the exact failure it
# exists to prevent. The npm copy is gone; any node_modules hit is now a
# duplicate by definition.
canonical_codex="/opt/homebrew/bin/codex"
if [ -x "$canonical_codex" ]; then
  while IFS= read -r dup; do
    [ -n "$dup" ] || continue
    # .../node/<ver>/lib/node_modules/@openai/codex -> .../node/<ver>
    node_root="${dup%/lib/node_modules/@openai/codex}"
    echo "$(date '+%Y-%m-%dT%H:%M:%S') WARNING: duplicate codex install at $dup"
    echo "  It shadows $canonical_codex wherever that node version is active. Removing."
    if [ -x "$node_root/bin/npm" ]; then
      if "$node_root/bin/npm" uninstall -g @openai/codex >/dev/null 2>&1; then
        echo "  removed via $node_root/bin/npm"
      else
        echo "  ERROR: uninstall failed - remove $dup by hand"
      fi
    elif rm -rf "$dup"; then
      echo "  removed the directory (no npm at $node_root/bin/npm)"
    else
      echo "  ERROR: could not remove $dup"
    fi
  done < <(find "$HOME/.local/share/mise/installs/node" -maxdepth 5 -type d \
    -path "*/node_modules/@openai/codex" 2>/dev/null)
fi

# If an npm upgrade replaced the server bundle, the LOCAL PATCH hunks are gone
# and restarting would run it unpatched. reapply-patches.sh restarts and
# health-checks on success, so the plain kickstart is skipped in that case. If
# reapply fails, restart anyway - running unpatched beats not running - and
# leave a loud line so the failure is visible in this log.
dist="$HOME/.local/opt/copilot-api/node_modules/@jeffreycao/copilot-api/dist"
bundle="$(ls "$dist"/server-*.js 2>/dev/null | grep -v '\.map$' | head -1 || true)"
if [ -n "$bundle" ] && ! grep -q "LOCAL PATCH" "$bundle"; then
  echo "$(date '+%Y-%m-%dT%H:%M:%S') server bundle is UNPATCHED ($bundle) - running reapply-patches.sh"
  if "$HOME/.local/share/copilot-api/reapply-patches.sh"; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S') local patches reapplied and service restarted"
    exit 0
  fi
  echo "$(date '+%Y-%m-%dT%H:%M:%S') ERROR: reapply-patches.sh FAILED - service is running UNPATCHED; port the patches by hand (see reapply-patches.sh header)"
fi

launchctl kickstart -k "$service"
