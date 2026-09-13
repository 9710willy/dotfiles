#!/bin/bash
# Restart copilot-api when it is down or wedged in ways KeepAlive cannot see.
#
# Failure modes covered (all observed 2026-08-14):
#   DOWN:  the process is not listening at all. launchd in this gui domain
#          fails to spawn on KeepAlive/RunAtLoad, so a crash (e.g. token
#          "fetch failed" when restarted before Wi-Fi is up post-wake) can
#          leave the port dead indefinitely. A dead proxy also writes no log
#          lines, so only a port check can catch this.
#   WAKE:  system sleep kills the upstream sockets and wedges the connection
#          pool. launchd cannot run this job while asleep, so a gap since
#          the last run of >WAKE_GAP seconds means the Mac slept; restart
#          preemptively. (sleepwatcher's ~/.wakeup usually beats this and
#          resyncs the state file so this path stays quiet.)
#   SCAN:  wedge signatures in the log bytes appended since the last run -
#          the lines carry no timestamp, so recency comes from a saved byte
#          offset:
#            - "did not return headers within" ERROR (client waited out the
#              proxy's full 300s header timeout)
#            - POST /responses ending 499/500 after >=20s (clients gave up
#              earlier; codex retries produce bursts)
#          Trigger: >=2 of those and zero completed responses. Any "m200"
#          line in the window vetoes: partially-slow is not wedged.
#          The status code sits inside ANSI color codes ("...[33m499[0m"),
#          so the literal "m499"/"m200" match is on purpose - durations
#          never contain m<digit>.
#
# All restarts go through ensure-up.sh, which verifies the port afterwards
# and escalates to bootout+bootstrap - a bare kickstart -k can kill the
# process and never get a replacement in this domain.
#
# State file: line 1 = log byte offset, line 2 = epoch of last run.
#
# Env overrides, for testing only:
#   DRY_RUN=1        log the decision but skip the restart
#   WATCHDOG_LOG     scan this file instead of the live log
#   WATCHDOG_STATE   state file path
set -uo pipefail

log="${WATCHDOG_LOG:-$HOME/Library/Logs/copilot-api.log}"
state="${WATCHDOG_STATE:-$HOME/.local/share/copilot-api/.watchdog-offset}"
ensure="$HOME/.local/share/copilot-api/ensure-up.sh"
WAKE_GAP=1500
# A tick is scheduled every 10 minutes. Anything past this without being a sleep
# is the scheduler running late, which is worth a line even though it is not
# worth a restart.
LATE_TICK=660

# Diagnostics only, and run as a SUBPROCESS rather than sourced. Sourcing let
# the probe change this script's `set` flags, and a top-level `exit` in it would
# have terminated the watchdog with status 0 before the port check - a silent
# dead watchdog. A child process can do neither. machine-state.sh bounds itself
# and always exits 0, so the `||` is belt-and-braces for the file going missing.
probe="$HOME/.local/share/copilot-api/machine-state.sh"
machine_state() { "$probe" 2>/dev/null || echo "load=? memfree=? swap=? compressed=? top=? (probe unavailable)"; }

now=$(date +%s)
size=0
[ -f "$log" ] && size=$(stat -f%z "$log")

kick() {
	ts="$(date '+%Y-%m-%dT%H:%M:%S')"
	# Diagnostics run on BOTH paths, and before the DRY_RUN return, so a dry run
	# actually exercises them. Emitted before ensure-up because on a stalled
	# machine ensure-up can take minutes, and this is the only snapshot of the
	# state that caused it.
	echo "$ts machine: $(machine_state)"
	# There used to be a `sleep 1` here timed with $SECONDS, to measure scheduler
	# dilation. Removed: it sat in front of the restart, and its cost scaled with
	# the exact fault it measured - at the 87x dilation this file documents, a
	# `sleep 1` becomes ~90s of dead time before the first kickstart. The datum
	# was redundant anyway. ensure-up already prints "not listening after
	# kickstart (try N)" three times per run around sleeps it is paying for
	# regardless, and that is precisely how the 261s figure was derived.
	if [ "${DRY_RUN:-}" = "1" ]; then
		echo "$ts DRY_RUN: $1 - would restart"
		return 0
	fi
	echo "$ts $1 - restarting via ensure-up"
	"$ensure"
}

listening() { lsof -nP -iTCP:4141 -sTCP:LISTEN -t >/dev/null 2>&1; }

if [ ! -f "$state" ]; then
	# First run: start from EOF. Scanning history would count errors a past
	# restart already cleared and bounce the service for no reason.
	printf '%s\n%s\n' "$size" "$now" > "$state"
	exit 0
fi

offset=$(sed -n 1p "$state")
last=$(sed -n 2p "$state")
printf '%s\n%s\n' "$size" "$now" > "$state"

# DOWN beats everything: a dead proxy writes no log lines to scan.
# Skipped in test mode when pointing at a fake log - the real proxy's state
# is irrelevant to those tests.
if [ -z "${WATCHDOG_LOG:-}" ] && ! listening; then
	kick "proxy not listening on 4141"
	exit $?
fi

# Pre-heartbeat state file (one line) has no epoch: initialize only.
if [ -n "$last" ] && [ $((now - last)) -gt "$WAKE_GAP" ]; then
	kick "no tick for $((now - last))s (system slept) - upstream sockets likely dead"
	exit $?
fi

# Not a restart condition - just evidence. A tick that is late but under
# WAKE_GAP used to leave no trace, which is the gap that made the 2026-08-18
# stall invisible until it had already taken the service down.
#
# This line used to assert "not long enough to be sleep". That was false and
# actively misleading: nothing here observes sleep, and pmset shows this host
# producing ~3 sleeps a day whose duration lands inside 660..1500s, so the line
# blamed the scheduler for pure sleeps in the very log it exists to make
# trustworthy. kern.waketime is authoritative, costs ~11ms, and its value
# matched the 07:06:59 "wake:" line in this log exactly. Emit the dimensions and
# let the reader conclude; suppress entirely when the wake lands in the gap,
# because then sleep fully explains it.
#
# Note also that `last` is the PREVIOUS RUN'S START, so the gap includes that
# run's own duration - and ensure-up runs of 9-29 minutes are on record. Such a
# gap is self-inflicted, not evidence about the machine, which is another reason
# not to assert a cause.
if [ -n "$last" ] && [ $((now - last)) -gt "$LATE_TICK" ]; then
	gap=$((now - last))
	# WATCHDOG_WAKETIME is a test seam. Without it neither arm of this branch is
	# reachable on demand - you would have to make the machine actually sleep for
	# a duration inside 660..1500s to see it, which is why the false "not long
	# enough to be sleep" line shipped unnoticed in the first place.
	wake="${WATCHDOG_WAKETIME:-$(sysctl -n kern.waketime 2>/dev/null | sed -n 's/^{ sec = \([0-9]*\).*/\1/p')}"
	if [ -n "$wake" ] && [ "$wake" -gt "$last" ] 2>/dev/null; then
		: # woke during the gap - sleep explains it, nothing to report
	else
		echo "$(date '+%Y-%m-%dT%H:%M:%S') tick gap=${gap}s (scheduled 600s) no_wake_in_gap last_wake=${wake:-unknown} - machine: $(machine_state)"
	fi
fi

# daily-maintenance.sh truncates the log in place at 04:00; a file smaller
# than the saved offset means everything in it is new.
[ "$size" -lt "${offset:-0}" ] && offset=0

bad=0 ok=0
if [ "$size" -gt "${offset:-0}" ]; then
	read -r bad ok < <(tail -c +"$((offset + 1))" "$log" | awk '
		/^--> POST \/responses / && /m(499|500)/ {
			d=$NF
			if (d ~ /^[0-9]+s$/) { sub(/s$/, "", d); if (d+0 >= 20) bad++ }
		}
		/^--> POST \/responses / && /m200/ { ok++ }
		/did not return headers within/    { bad++ }
		END { print bad+0, ok+0 }')
fi

if [ "$bad" -ge 2 ] && [ "$ok" -eq 0 ]; then
	kick "$bad hung/timed-out completions, 0 successes since last check"
fi
