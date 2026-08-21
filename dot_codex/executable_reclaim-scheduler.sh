#!/bin/bash
# Hourly driver for reclaim-disk.sh.
#
# REWRITTEN 2026-08-19 together with reclaim-disk.sh. History:
#   * A daily 04:30 slot never fired once - codex resume sessions stay open
#     overnight and the old reclaim-disk.sh refused to run while any codex was
#     alive.
#   * Moving to hourly did not help either, for the same reason: the refusal was
#     unconditional, so every one of the 24 daily attempts hit it. The stamp file
#     .reclaim-last-success was never created and ~/.codex reached 9.7GB.
#
# reclaim-disk.sh now prunes online, and only VACUUM needs the db unlocked. So
# the two phases get SEPARATE stamps. A vacuum that cannot get the lock must not
# stop the prune from being recorded as done - that coupling is what broke the
# job before.
#
#   .reclaim-last-prune    prune ran today (works with codex open, so this
#                          should be stamped every day)
#   .reclaim-last-vacuum   vacuum landed today (opportunistic: needs the first
#                          hour codex happens to be closed; exit 75 means
#                          deferred, which is normal and stays out of the log)
#
# Rollouts are still never deleted (no --rollouts flag on purpose): deleting one
# means that thread can no longer be resumed. 4.8GB currently sits there; prune
# it by hand with `reclaim-disk.sh --rollouts` if the disk ever gets tight.
set -euo pipefail

codex_home="$HOME/.codex"
prune_stamp="$codex_home/.reclaim-last-prune"
vacuum_stamp="$codex_home/.reclaim-last-vacuum"
today="$(date +%Y-%m-%d)"

run_phase() {
  local phase="$1" stamp="$2" flag="$3"
  [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$today" ] && return 0

  # `|| status=$?` on its own, not `&& status=0 || status=$?`: in the A && B || C
  # form a failure of B silently runs C too, so the recorded status would be a
  # lie the one time it matters.
  local out status=0
  out="$("$codex_home/reclaim-disk.sh" "$flag" 2>&1)" || status=$?

  case "$status" in
    0)
      echo "$today" >"$stamp"
      echo "=== $(date '+%Y-%m-%dT%H:%M:%S') $phase"
      echo "$out"
      ;;
    75)
      # Vacuum deferred: the db is locked by a running codex. Expected most
      # hours, so it is not logged - at 24 attempts a day it would drown the
      # log. No stamp, so the next hour tries again.
      ;;
    *)
      echo "=== $(date '+%Y-%m-%dT%H:%M:%S') $phase FAILED (exit $status)"
      echo "$out"
      return "$status"
      ;;
  esac
}

rc=0
run_phase "prune" "$prune_stamp" "--prune-only" || rc=$?
run_phase "vacuum" "$vacuum_stamp" "--vacuum-only" || rc=$?
exit "$rc"
