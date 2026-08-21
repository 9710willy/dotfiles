#!/bin/bash
# Reclaim Codex disk.
#
# REWRITTEN 2026-08-19. The previous version refused to do anything while any
# codex process was alive. Codex resume sessions are open essentially all the
# time here, so the job never ran once: the scheduler's stamp file was never
# created, and ~/.codex reached 9.7GB.
#
# Measured 2026-08-19 (~9.7GB total):
#   ~/.codex/sessions       4.8GB   rollout files (resume transcripts)
#   logs_2.sqlite           3.7GB   102136 rows, 3.0GB of it feedback_log_body
#   thread_history_1.sqlite 1.0GB   thread_items, shown in the TUI
#
# What changed and why:
#   * PRUNE now runs with codex open. Verified 2026-08-19: `BEGIN IMMEDIATE`
#     against logs_2.sqlite succeeded while two codex processes held it open.
#     The db is WAL, so a batched DELETE takes the write lock only for the
#     length of each batch.
#   * VACUUM is still lock-hungry, so it is ATTEMPTED and allowed to fail. A
#     "database is locked" result is reported and skipped, not treated as an
#     error - the pages the prune freed stay on the freelist and get reused, so
#     the db stops growing even on a day the vacuum never lands.
#   * The old "cutoff matches every row" refusal was removed. It existed to
#     catch a seconds-vs-milliseconds mistake, but it fires on a legitimate
#     state too: nothing has inserted into `logs` since 2026-08-14 (there is a
#     `block_log_inserts` BEFORE INSERT ... RAISE(IGNORE) trigger on the table),
#     so within days of that every row is older than KEEP_DAYS and the refusal
#     would have killed the job a second time. The unit is now checked
#     DIRECTLY, by rendering MAX(ts) and requiring a sane year.
#
# Rollouts are still NOT deleted unless --rollouts is passed: deleting one means
# that thread can no longer be resumed.
#
# Usage:
#   reclaim-disk.sh                 # prune, then try to vacuum
#   reclaim-disk.sh --prune-only    # delete old rows, never vacuum
#   reclaim-disk.sh --vacuum-only   # only vacuum
#   reclaim-disk.sh --rollouts      # also delete rollouts older than KEEP_DAYS
#   KEEP_DAYS=14 reclaim-disk.sh    # change the retention window
#
# Exit codes: 0 success, 1 real failure, 75 deferred. 75 means the db was locked
# so a phase could not finish; both phases use it, and the next run retries.
set -euo pipefail

KEEP_DAYS="${KEEP_DAYS:-7}"
BATCH="${BATCH:-2000}"
BUSY_MS="${BUSY_MS:-30000}"
MAX_SECONDS="${MAX_SECONDS:-600}"
codex_home="$HOME/.codex"
db="$codex_home/logs_2.sqlite"
sessions="$codex_home/sessions"

prune_rollouts=false
do_prune=true
do_vacuum=true
# Set when the vacuum could not complete. Checked once at the very end so exit 75
# means the same thing on every entry point; previously it fired only under
# --vacuum-only, so a plain run that deferred its vacuum still exited 0 and told
# the caller the space had been reclaimed.
vacuum_deferred=false
case "${1:-}" in
  --rollouts) prune_rollouts=true ;;
  --prune-only) do_vacuum=false ;;
  --vacuum-only) do_prune=false ;;
  "") ;;
  *)
    echo "ERROR: unknown argument '$1'"
    exit 1
    ;;
esac

# A SQLite database on disk is the main file PLUS its -wal and -shm. Reporting
# only the main file understates usage by exactly the amount a failed checkpoint
# left behind - i.e. it hides the one failure this script most needs to show.
# Observed 2026-08-19: main file 1.9G printed as a 1.8G win while the -wal still
# held 1.9G.
size() { du -ch "$1" "$1-wal" "$1-shm" 2>/dev/null | tail -1 | cut -f1; }

# Every reporting read goes through the read-only URI, so a figure printed for a
# human can never take a lock away from a live codex.
# NOT `file:$db?mode=ro`. A read-only connection to a WAL-mode database has to
# CREATE the -shm file when it is missing, and it cannot, so every table read
# fails with "unable to open database file (14)". The -shm and -wal are absent
# exactly when the last connection closed cleanly - which is the state this
# script's own successful vacuum+checkpoint leaves behind. Observed 2026-08-19:
# the live job aborted with "cannot read ... to check the timestamp unit" the
# first time it ran after a clean vacuum with codex closed.
#
# Read-only bought nothing here anyway: the same script DELETEs and VACUUMs this
# file a few lines later. The busy timeout matters for the same reason it does
# on the write path - a live codex reader can hold the lock.
read_db() { sqlite3 -cmd ".timeout $BUSY_MS" "$db" "$1"; }

# Both writing phases need the same three things: the busy timeout, the
# statement's stdout, and its stderr TEXT - the message is the only way to tell a
# transient lock from a real fault. Results land in sql_out and sql_err.
#
# `-cmd ".timeout N"` and NOT `PRAGMA busy_timeout=N;` inside the SQL: the PRAGMA
# form PRINTS its value, so sqlite3 emitted "30000\n<changes>". The first draft of
# this script then stripped non-digits, which glued the two lines into one number
# that could never be 0 - the loop spun for 11 minutes deleting nothing before it
# was killed (2026-08-19). Dot-commands print nothing.
#
# `sql_out=$(...) || status=$?` and not a bare assignment: under `set -e` a bare
# assignment from a failing command aborts the script mid-loop with no message.
sql_out=""
sql_err=""
write_db() {
  local err_file status=0
  err_file="$(mktemp -t reclaim-sql)"
  sql_out="$(sqlite3 -cmd ".timeout $BUSY_MS" "$db" "$1" 2>"$err_file")" || status=$?
  sql_err="$(cat "$err_file" 2>/dev/null || true)"
  rm -f "$err_file"
  return "$status"
}

# One error model for both phases. A lock is transient, so it is a DEFERRAL -
# quiet, exit 75, retried next hour. Treating it as a hard failure meant one
# 30s-exceeding write conflict wrote "prune FAILED" to the log and left it
# indistinguishable from a bad schema or a full disk.
sql_locked() { printf '%s' "$sql_err" | grep -qi "locked\|busy"; }

# PRAGMA wal_checkpoint reports failure IN ITS RESULT ROW ("busy|log|checkpointed"),
# not in its exit status: a checkpoint blocked by a live reader prints "1|N|0" and
# exits 0. Discarding stdout therefore discards the only signal that matters.
# Echoes the busy flag (1 = the WAL was NOT folded back), or 1 if the call failed.
checkpoint_busy() {
  local out
  out=$(sqlite3 -cmd ".timeout $BUSY_MS" "$1" "PRAGMA wal_checkpoint(TRUNCATE);" 2>/dev/null) || {
    echo 1
    return
  }
  case "$out" in
    0\|*) echo 0 ;;
    *) echo 1 ;;
  esac
}

# Rollout transcripts older than the retention window. 2>/dev/null plus the
# caller's `|| x="?"`: unguarded, a missing or unreadable sessions directory makes
# find exit 1, pipefail propagates it, and set -e kills the script with exit 1 and
# no output - discarding a prune that had already worked.
old_rollouts() { find "$sessions" -name "*.jsonl" -type f -mtime "+$KEEP_DAYS" 2>/dev/null | wc -l | tr -d ' '; }

# UPDATED 2026-08-21: codex moved from the npm install to the Homebrew CASK, so
# the old `codex-darwin-arm64/vendor/...` pattern can never match again. Left
# alone, this reported "codex is closed" while two sessions held the db open,
# and every deferred vacuum below looked like an unexplained failure. The cask
# runs the binary straight out of the Caskroom, plus a codex-code-mode-host
# child; matching either is enough to know a writer is live.
if pgrep -f "Caskroom/codex/.*/bin/codex" >/dev/null 2>&1 ||
  pgrep -f "codex-darwin-arm64/vendor/.*/bin/codex" >/dev/null 2>&1 ||
  pgrep -f "bin/codex resume" >/dev/null 2>&1; then
  echo "note: codex is running - pruning online, vacuum may be deferred"
fi

total_before=$(du -sh "$codex_home" | cut -f1) || total_before="?"
echo "codex home before: $total_before"

if [ "$do_prune" = true ] && [ -f "$db" ]; then
  echo "logs_2.sqlite before: $(size "$db")"

  # Unit guard, replacing the old all-rows-doomed heuristic. `ts` is epoch
  # SECONDS. If it were milliseconds, datetime(MAX(ts),'unixepoch') renders in
  # the year 57000-odd; if it were microseconds, further out still. Requiring a
  # plausible year checks the unit directly.
  #
  # COUNT(*) is read in the SAME query, and the guard is SKIPPED when the table
  # is empty. MAX() over zero rows is NULL, not an error: sqlite3 prints an empty
  # line and exits 0. An earlier version of this guard treated that empty string
  # as a failed unit check and exited 1 - which would have bricked the prune
  # permanently from 2026-08-21, because the block_log_inserts trigger means
  # `logs` can never gain a row again, so the table empties and stays empty. That
  # is the same self-bricking shape as the all-rows-doomed heuristic this guard
  # replaced. An empty table is a SUCCESS: there is nothing left to prune.
  #
  # That COUNT(*) is also the "before" figure in the summary below. Asking for it
  # again is a second full scan of a multi-GB table for a number already in hand.
  #
  # A read failure is reported as itself, not as a unit error - the old
  # `2>/dev/null || echo 0` blamed every unreadable db on the wrong cause.
  if ! unit_probe=$(read_db "SELECT COUNT(*), IFNULL(CAST(strftime('%Y', datetime(MAX(ts),'unixepoch')) AS INTEGER), 0) FROM logs;"); then
    echo "ERROR: cannot read $db to check the timestamp unit"
    exit 1
  fi
  rows_before="${unit_probe%%|*}"
  newest_year="${unit_probe##*|}"
  if [ "$rows_before" -gt 0 ] && { [ "$newest_year" -lt 2020 ] || [ "$newest_year" -gt 2100 ]; }; then
    echo "REFUSING: MAX(ts) renders as year '$newest_year', which is not a plausible date."
    echo "The ts column is not epoch seconds. Check it before rerunning."
    exit 1
  fi

  now=$(date +%s)
  cutoff_s=$((now - KEEP_DAYS * 86400))
  deadline=$((now + MAX_SECONDS))

  # Batched delete: one transaction per batch, so the write lock is held for a
  # short burst instead of the whole 3GB.
  deleted_total=0
  batches=0
  while :; do
    if ! write_db "DELETE FROM logs WHERE id IN (SELECT id FROM logs WHERE ts < $cutoff_s LIMIT $BATCH); SELECT changes();"; then
      # This loop is idempotent - every batch re-selects by ts - so losing a
      # race with a live codex writer costs nothing but a retry.
      if sql_locked; then
        echo "prune DEFERRED after $deleted_total row(s): database is locked. Retrying next run."
        exit 75
      fi
      echo "ERROR: delete batch failed after $deleted_total row(s): $sql_err"
      exit 1
    fi
    # Strict integer check: it turns any future change in sqlite3's output into
    # an immediate hard stop instead of the silent infinite loop described in
    # write_db above.
    deleted="$sql_out"
    case "$deleted" in
      '' | *[!0-9]*)
        echo "ERROR: expected a plain row count from sqlite3, got: '$deleted'"
        echo "Stopping rather than looping. Deleted $deleted_total row(s) so far."
        exit 1
        ;;
    esac
    [ "$deleted" -eq 0 ] && break
    deleted_total=$((deleted_total + deleted))
    batches=$((batches + 1))

    # No per-batch checkpoint. It was added on the belief that a bulk delete
    # grows the WAL by the size of the deleted rows; measured 2026-08-19, a
    # 2000-row / ~60MB batch grew the -wal by 90KB (0.15%). So it bought ~52
    # extra sqlite3 spawns and lock attempts per prune, and its result was
    # discarded anyway. One checked checkpoint after the vacuum is what
    # actually returns the space.

    # Progress and a wall-clock budget: this loop is the only thing between
    # "before" and the summary, and launchd's log is the only place a human can
    # see it. A silent multi-minute run is indistinguishable from a hung one -
    # that is what led to killing the first version blind.
    if [ $((batches % 10)) -eq 0 ]; then
      echo "  ... $deleted_total row(s) in $batches batches, $(($(date +%s) - now))s elapsed"
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      echo "prune budget of ${MAX_SECONDS}s exhausted after $deleted_total row(s); the rest resumes next run"
      break
    fi
  done

  rows_after=$(read_db "SELECT COUNT(*) FROM logs;") || rows_after="?"
  echo "logs_2.sqlite pruned: rows $rows_before -> $rows_after (deleted $deleted_total older than ${KEEP_DAYS}d)"
fi

if [ "$do_vacuum" = true ] && [ -f "$db" ]; then
  # VACUUM rewrites the file. Without it the pages the prune freed stay on the
  # freelist: the db stops growing but does not shrink.
  free_mb=$(read_db "SELECT (SELECT * FROM pragma_freelist_count) * (SELECT * FROM pragma_page_size) / 1048576;" 2>/dev/null) || free_mb="?"
  echo "vacuum: ${free_mb}MB on the freelist, attempting..."
  if write_db "VACUUM;"; then
    # VACUUM in WAL mode SUCCEEDS with live readers - it writes the whole
    # rewritten db into the WAL, so the main file shrinks and the -wal grows to
    # match, for no net saving. Observed 2026-08-19: 3.7GB db became 1.9GB db +
    # 1.9GB wal. Folding the WAL back is the step that actually returns the
    # space, so its result decides whether this run succeeded - a busy
    # checkpoint here means disk went UP, not down.
    if [ "$(checkpoint_busy "$db")" -ne 0 ]; then
      echo "vacuum DEFERRED: the rewrite is still in the WAL - a live codex reader"
      echo "blocked the checkpoint, so disk usage has NOT gone down. Not stamping;"
      echo "the next run retries. Close codex and rerun --vacuum-only to settle it."
      vacuum_deferred=true
    else
      echo "logs_2.sqlite after:  $(size "$db")"
    fi
  elif sql_locked; then
    # Not "the pages get reused": nothing ever inserts into `logs` again (the
    # block_log_inserts trigger), so a permanently deferred vacuum means the
    # freed pages are dead space for good, not a buffer for future writes.
    echo "vacuum DEFERRED: database is locked by a running codex. ${free_mb}MB of freed"
    echo "pages stay on disk as dead space - nothing inserts into logs any more, so"
    echo "they will never be reused. Close codex and rerun --vacuum-only to reclaim."
    vacuum_deferred=true
  else
    echo "ERROR: vacuum failed: $sql_err"
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# thread_history_1.sqlite - age-based prune. ADDED 2026-08-21.
#
# WHY THIS EXISTS SEPARATELY from the --rollouts block below: that one keeps a
# thread only if its rollout .jsonl still exists on disk. That was the right key
# while rollouts were the system of record, but codex 0.149 stopped keeping them
# - measured 2026-08-21, 42 rollouts (4.0G) at 00:35 became 3 (5.3M) by 09:00
# while thread_history kept all 833 threads. So the rollout-keyed prune would now
# delete 830 of 833 threads, and on a plain nightly run (no --rollouts) it never
# fires at all: the db grew to 846M / 125,586 items / 635M of item_json in 16
# days, about 40MB a day, with nothing bounding it.
#
# This block keys on AGE instead, runs on every prune, and is the one that keeps
# the file flat. A thread survives if it has activity inside the window - MAX,
# not MIN, so a thread started 3 weeks ago but used yesterday is kept - or if it
# is pinned in the TUI.
#
# Same empty-list rule as the block below: an empty keep list matches every row,
# and it is far more likely to mean "the query failed" than "you have no
# threads", so an empty list SKIPS the delete instead of wiping the history.
thread_db="$codex_home/thread_history_1.sqlite"
state_db="$codex_home/state_5.sqlite"
if [ "$do_prune" = true ] && [ -f "$thread_db" ]; then
  cutoff_ms=$((($(date +%s) - KEEP_DAYS * 86400) * 1000))
  keep_ids="$(mktemp -t reclaim-thread-keep)"
  th_before="$(sqlite3 -cmd ".timeout $BUSY_MS" "file:$thread_db?mode=ro" \
    "SELECT COUNT(DISTINCT thread_id) FROM thread_items;" 2>/dev/null || echo "?")"

  # Recent threads. Read-only URI so this can never be the thing that corrupts
  # the db if it is killed mid-read.
  sqlite3 -cmd ".timeout $BUSY_MS" "file:$thread_db?mode=ro" \
    "SELECT thread_id FROM thread_items GROUP BY thread_id HAVING MAX(created_at_ms) >= $cutoff_ms;" \
    >"$keep_ids" 2>/dev/null || true

  # Pinned threads, whatever their age - the user pinned them on purpose. If this
  # read fails the prune is SKIPPED rather than run without it, because the cost
  # of guessing wrong is deleting a thread that was deliberately kept.
  pinned_ok=true
  pinned="$(sqlite3 -cmd ".timeout $BUSY_MS" "file:$state_db?mode=ro" \
    "SELECT id FROM threads WHERE is_pinned = 1;" 2>/dev/null)" || pinned_ok=false
  if [ "$pinned_ok" = true ]; then
    [ -z "$pinned" ] || printf '%s\n' "$pinned" >>"$keep_ids"
    sort -u -o "$keep_ids" "$keep_ids"
  fi

  if [ "$pinned_ok" != true ]; then
    echo "thread history: SKIPPED - could not read pinned threads from $(basename "$state_db"); refusing to prune without that list"
  elif [ ! -s "$keep_ids" ]; then
    echo "thread history: SKIPPED - keep list came out empty, refusing to treat that as \"delete everything\""
  elif ! th_err="$(
    sqlite3 -cmd ".timeout $BUSY_MS" "$thread_db" 2>&1 >/dev/null <<-SQL
		.mode csv
		CREATE TEMP TABLE keep(id TEXT PRIMARY KEY);
		.import $keep_ids keep
		BEGIN IMMEDIATE;
		DELETE FROM thread_items                    WHERE thread_id NOT IN (SELECT id FROM keep);
		DELETE FROM thread_turns                    WHERE thread_id NOT IN (SELECT id FROM keep);
		DELETE FROM thread_history_projection_state WHERE thread_id NOT IN (SELECT id FROM keep);
		COMMIT;
	SQL
  )"; then
    if printf '%s' "$th_err" | grep -qi "locked\|busy"; then
      echo "thread history: DEFERRED - $(basename "$thread_db") is locked by a running codex; the next run retries"
      vacuum_deferred=true
    else
      echo "ERROR: thread history prune failed: $th_err"
      exit 1
    fi
  else
    th_after="$(sqlite3 -cmd ".timeout $BUSY_MS" "file:$thread_db?mode=ro" \
      "SELECT COUNT(DISTINCT thread_id) FROM thread_items;" 2>/dev/null || echo "?")"
    echo "thread history pruned: threads $th_before -> $th_after (dropped those with no activity in ${KEEP_DAYS}d, kept pinned)"
  fi
  rm -f "$keep_ids"
fi

# The vacuum is its OWN phase, not a step inside the prune above. Nested there it
# was reachable only when do_prune was true, so `--vacuum-only` - the command you
# run precisely because codex was open during the prune and the space was never
# returned - skipped thread_history entirely and reported success (2026-08-21).
# Every other db in this script separates the two phases for the same reason.
if [ "$do_vacuum" = true ] && [ -f "$thread_db" ]; then
  # Same WAL rule as logs_2.sqlite: VACUUM lands the rewrite in the -wal, and only
  # a checkpoint reporting busy=0 actually returns the space. With a live codex
  # this makes disk usage go UP until the checkpoint lands, so a busy result is
  # reported as a deferral, not a success.
  th_free_mb="$(sqlite3 -cmd ".timeout $BUSY_MS" "file:$thread_db?mode=ro" \
    "SELECT (SELECT * FROM pragma_freelist_count) * (SELECT * FROM pragma_page_size) / 1048576;" 2>/dev/null || echo "?")"
  echo "thread history vacuum: ${th_free_mb}MB on the freelist, attempting..."
  if sqlite3 -cmd ".timeout $BUSY_MS" "$thread_db" "VACUUM;" >/dev/null 2>&1; then
    if [ "$(checkpoint_busy "$thread_db")" -ne 0 ]; then
      echo "thread history: vacuum DEFERRED - the rewrite is still in the WAL, a live"
      echo "codex reader blocked the checkpoint. Close codex and rerun --vacuum-only."
      vacuum_deferred=true
    else
      echo "thread history after: $(size "$thread_db")"
    fi
  else
    echo "thread history: vacuum DEFERRED - $(basename "$thread_db") is locked by a running codex."
    vacuum_deferred=true
  fi
fi

if [ "$prune_rollouts" = true ]; then
  echo "rollouts before: $(size "$sessions")"
  count=$(old_rollouts) || count="?"
  find "$sessions" -name "*.jsonl" -type f -mtime "+$KEEP_DAYS" -delete
  # -mindepth 1: without it this deletes the sessions ROOT once a --rollouts run
  # empties it, and every later run then dies counting rollouts - an exit 1 with
  # no output, after the prune had already succeeded.
  find "$sessions" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  echo "rollouts after:  $(size "$sessions")  ($count files older than ${KEEP_DAYS}d deleted - those threads can no longer be resumed)"

  # Keep the TUI thread list in step with the transcripts. Deleting a rollout
  # without this leaves its thread in the picker, where selecting it fails: the
  # transcript it needs is gone. All three tables key on thread_id.
  #
  # Driven off the filenames that SURVIVED, not off the ones just deleted, so it
  # is idempotent and also sweeps up any thread orphaned by an earlier run.
  # Measured 2026-08-19 on the first paired run: 40942 items / 233 turns / 119
  # projection rows for 118 orphaned threads, taking the db from 1.0G to 803M.
  #
  # Safety: if the id list comes out EMPTY the delete is skipped entirely. An
  # empty list would otherwise match every row and wipe the whole history - and
  # an empty list is far more likely to mean "find failed" than "no threads".
  thread_db="$codex_home/thread_history_1.sqlite"
  if [ -f "$thread_db" ]; then
    keep_ids="$(mktemp -t reclaim-keep-ids)"
    find "$sessions" -name "*.jsonl" -type f 2>/dev/null |
      grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' |
      sort -u >"$keep_ids" || true
    if [ ! -s "$keep_ids" ]; then
      echo "thread list: SKIPPED - no rollout ids found, refusing to treat that as \"delete everything\""
    # SQL goes in on STDIN, not as an argument. sqlite3 does not run dot-commands
    # from a command-line SQL argument - it parses the text differently and dies
    # with `extra argument: "TEMP"`, so `.import` is unreachable that way.
    # Observed 2026-08-19: as an argument this failed every time, and because the
    # error was thrown away it was reported as "locked", blaming the wrong cause
    # exactly the way the old `2>/dev/null || echo 0` unit guard did.
    elif ! thread_err="$(
      sqlite3 -cmd ".timeout $BUSY_MS" "$thread_db" 2>&1 >/dev/null <<-SQL
		.mode csv
		CREATE TEMP TABLE keep(id TEXT PRIMARY KEY);
		.import $keep_ids keep
		BEGIN IMMEDIATE;
		DELETE FROM thread_items                    WHERE thread_id NOT IN (SELECT id FROM keep);
		DELETE FROM thread_turns                    WHERE thread_id NOT IN (SELECT id FROM keep);
		DELETE FROM thread_history_projection_state WHERE thread_id NOT IN (SELECT id FROM keep);
		COMMIT;
	SQL
    )"; then
      if printf '%s' "$thread_err" | grep -qi "locked\|busy"; then
        echo "thread list: SKIPPED - $(basename "$thread_db") is locked; rerun --rollouts when codex is closed"
      else
        echo "thread list: SKIPPED - $(basename "$thread_db") prune failed: $thread_err"
      fi
    else
      # Same WAL rule as logs_2.sqlite: VACUUM lands the rewrite in the -wal, and
      # only a checkpoint that reports busy=0 actually returns the space.
      sqlite3 -cmd ".timeout $BUSY_MS" "$thread_db" "VACUUM;" >/dev/null 2>&1 || true
      if [ "$(checkpoint_busy "$thread_db")" -ne 0 ]; then
        echo "thread list: pruned to match, but the vacuum is still in the WAL (codex holds it open)"
      else
        echo "thread list: pruned to match - $(size "$thread_db")"
      fi
    fi
    rm -f "$keep_ids"
  fi
else
  pending=$(old_rollouts) || pending="?"
  echo "rollouts: left alone. $pending file(s) older than ${KEEP_DAYS}d ($(size "$sessions") total) could be freed with --rollouts"
fi

echo "codex home after:  $(du -sh "$codex_home" | cut -f1)  (was $total_before)"
echo
# thread_history_1.sqlite belongs in this list only when --rollouts did NOT run.
# With --rollouts it IS pruned, to keep the TUI picker from offering threads whose
# transcript has just been deleted.
if [ "$prune_rollouts" = true ]; then
  echo "Not touched on purpose: state_5.sqlite, memories_1.sqlite, queue_1.sqlite,"
  echo "goals_1.sqlite. (thread_history_1.sqlite WAS pruned, to match the rollouts.)"
else
  echo "Not touched on purpose: state_5.sqlite, memories_1.sqlite, queue_1.sqlite,"
  echo "goals_1.sqlite. (thread_history_1.sqlite is pruned by age on every run.)"
fi

[ "$vacuum_deferred" = true ] && exit 75
exit 0
