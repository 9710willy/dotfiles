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

now=$(date +%s)
size=0
[ -f "$log" ] && size=$(stat -f%z "$log")

kick() {
	ts="$(date '+%Y-%m-%dT%H:%M:%S')"
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
