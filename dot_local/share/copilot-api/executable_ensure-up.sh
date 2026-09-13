#!/bin/bash
# Kill-and-restart copilot-api, then make sure it actually came back.
#
# Two failure modes this covers (both observed 2026-08-14):
#   - launchd in this gui domain kills on kickstart -k and then fails to
#     spawn the replacement (KeepAlive included), turning a remedy restart
#     into an outage.
#   - the proxy exits 1 at startup when the network is not up yet (token
#     "fetch failed" right after wake, before Wi-Fi associates), so the
#     retries double as a wait-for-network.
# Escalates to bootout+bootstrap if plain kickstarts will not stick.
set -u

# Seams, defaulted to production. These exist because the escalation ladder was
# previously only ever exercised by `sed`-cloning this file to point at a fake
# service and port - i.e. the destructive bootout+bootstrap branch, the one most
# likely to cause an outage, was the one branch never run against the real
# script. LC_CMD makes lc()'s failure path deterministic: point it at a stub that
# exits 125 and the log line is reproducible without waiting for macOS to refuse
# an operation on its own.
service="${ENSURE_SERVICE:-gui/$(id -u)/com.willee1.copilot-api}"
plist="${ENSURE_PLIST:-$HOME/Library/LaunchAgents/com.willee1.copilot-api.plist}"
port="${ENSURE_PORT:-4141}"
lock="${ENSURE_LOCK:-$HOME/.local/share/copilot-api/.ensure-up.lock}"
domain="${ENSURE_DOMAIN:-gui/$(id -u)}"
LC_CMD="${LC_CMD:-launchctl}"
proxy_log="${ENSURE_PROXY_LOG:-$HOME/Library/Logs/copilot-api.log}"

ts() { date '+%Y-%m-%dT%H:%M:%S'; }
up() { lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; }

# Diagnostics, run as a SUBPROCESS rather than sourced. Sourcing let the probe
# change this script's `set` flags, and a top-level `exit` in it would have
# terminated this script before the lock and before the trap - so the restart
# ladder would never have run. machine-state.sh bounds itself and always exits 0.
probe="$HOME/.local/share/copilot-api/machine-state.sh"
machine_state() { "$probe" 2>/dev/null || echo "load=? memfree=? swap=? compressed=? top=? (probe unavailable)"; }

# Captured BEFORE the lock, and reused for the escalation line. The probe used to
# run inside the `echo` that gates bootout+bootstrap - the one step the log shows
# actually recovers this service (2026-08-21T18:36:24 "escalating" -> 18:36:28
# "recovered via bootstrap") - and inside the lock, whose staleness threshold is
# measured in minutes. Diagnostics must not gate the remedy.
state_at_start="$(machine_state)"

# Single-flight lock. Two callers reach this script independently - watchdog.sh
# (every 10 min, plus its own wake path) and sleepwatcher's ~/.wakeup - and on a
# wake both fire at once. Without a lock they interleave: one runs bootout while
# the other is mid-kickstart, so each undoes the other's recovery. That is what
# the 2026-08-18 08:11-08:12 log shows - two runs reporting "try 1/2/3" against
# each other before one finally got a bootstrap through, turning a ~15s recovery
# into ~30s of thrash.
#
# mkdir is the atomic primitive here: exactly one caller can create the
# directory, and it needs no flock(1) (which macOS does not ship).
#
# OWNERSHIP, not age. This used to clear any lock older than 5 minutes on the
# stated grounds that "this script's own worst case is well under a minute". The
# 2026-08-18 log disproves that: all twelve cycles ran 9-29 MINUTES
# (03:42:49 -> 04:11:49 = 29m00s), because each `sleep 3` took 34-261s on the
# stalled machine. So on a sick machine the lock looked stale for most of a live
# holder's life, and the wake hook would rmdir a running holder's lock and start
# a concurrent ladder - precisely the interleaving the lock exists to prevent.
# Worse, the release was unconditional, so the first holder's EXIT trap then
# removed the SECOND holder's lock, freeing it mid-ladder for a third caller.
# A pid plus `kill -0` decides liveness directly instead of guessing from age;
# mtime survives only as a backstop for a lock dir with no pid file (the tiny
# window between mkdir and the write below).
owned=0
acquire() { mkdir "$lock" 2>/dev/null && { echo $$ > "$lock/pid"; owned=1; return 0; }; return 1; }

if ! acquire; then
	holder="$(cat "$lock/pid" 2>/dev/null)"
	if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
		echo "$(ts) ensure-up: another run (pid $holder) is already restarting; waiting briefly for it"
	elif [ -n "$holder" ]; then
		echo "$(ts) ensure-up: clearing lock left by dead pid $holder"
		rm -f "$lock/pid" 2>/dev/null; rmdir "$lock" 2>/dev/null
	elif [ -n "$(find "$lock" -maxdepth 0 -mmin +5 2>/dev/null)" ]; then
		echo "$(ts) ensure-up: clearing a lock dir with no pid file, older than 5min"
		rmdir "$lock" 2>/dev/null
	fi
	if ! acquire; then
		# Do not claim success without checking. Every other exit 0 in this script
		# is gated on up(); this path used to exit 0 blind, so the watchdog recorded
		# a successful tick having done nothing, and if the winner then failed
		# nothing re-checked the port for a full 10 minutes. Both callers only run
		# when something is already wrong, so that is the case that matters.
		for _ in 1 2 3 4 5; do
			sleep 3
			up && exit 0
		done
		echo "$(ts) ensure-up: the other run did not restore port $port; exiting non-zero"
		exit 1
	fi
fi

# Release only what we own. rm -f first: rmdir will not remove a non-empty dir.
trap '[ "$owned" = 1 ] && [ "$(cat "$lock/pid" 2>/dev/null)" = "$$" ] && { rm -f "$lock/pid"; rmdir "$lock"; } 2>/dev/null' EXIT

# Every launchctl call used to be `launchctl ... 2>/dev/null` with its exit code
# unchecked, so when launchctl itself refused the operation there was no record
# of it anywhere. That is exactly what made 2026-08-18 undiagnosable: twelve
# consecutive cycles logged "FAILED - still not listening" over 5.5 hours
# without one word about WHY the kickstart/bootstrap did not take.
#
# It matters specifically on macOS 26: the gui/<uid> domain has been reported to
# reject kickstart and bootstrap with error 125 "Domain does not support
# specified action", and bootstrap is reported to fail silently after a
# successful bootout - leaving the agent booted out and never re-registered.
# This host is 26.6.2. If that ever happens here, the reason now lands in the
# log instead of being thrown away.
lc() {
	local out rc
	out="$("$LC_CMD" "$@" 2>&1)"
	rc=$?
	if [ "$rc" -ne 0 ]; then
		echo "$(ts) ensure-up: launchctl $* -> exit $rc${out:+ : $out}"
	fi
	return "$rc"
}

lc kickstart -k "$service" || true
for i in 1 2 3; do
	sleep 3
	up && exit 0
	echo "$(ts) ensure-up: not listening after kickstart (try $i)"
	lc kickstart "$service" || true
done
sleep 3
up && exit 0

echo "$(ts) ensure-up: escalating to bootout+bootstrap - machine at start: $state_at_start"
lc bootout "$service" || true
sleep 1
# bootstrap is the one step whose failure is unrecoverable rather than merely
# unsuccessful: bootout has already de-registered the agent, so KeepAlive and
# RunAtLoad are gone and there is no launchd supervision left to bring the proxy
# back on its own. The kickstart phase above gets four attempts; this used to get
# exactly one, and its exit code was discarded by `|| true`. A second bootstrap
# of an already-loaded label is a harmless no-op, so retrying costs nothing.
if ! lc bootstrap "$domain" "$plist"; then
	sleep 2
	if ! lc bootstrap "$domain" "$plist"; then
		echo "$(ts) ensure-up: CRITICAL - agent is booted out and NOT registered; launchd supervision is gone. Recover with: launchctl bootstrap $domain $plist"
	fi
fi
# RunAtLoad spawn is unreliable in this domain - kick explicitly.
lc kickstart "$service" || true
for i in 1 2 3; do
	sleep 3
	up && { echo "$(ts) ensure-up: recovered via bootstrap"; exit 0; }
done

# This is the line that has to explain the next 2026-08-18, and machine state
# alone cannot. It fires precisely when launchctl reported success but the port
# is dead - and in that state lc() is silent by design, because it only speaks on
# a non-zero exit. So ask launchd what it believes: `state`, `runs`, `pid` and
# `last exit code` separate a throttled crash-loop from a wedged process from an
# agent that was booted out and never re-registered. And copy the proxy's own
# last words in here, because daily-maintenance.sh truncates copilot-api.log at
# 04:00 and the 2026-08-18 outage ran 02:38-08:12, straight through it - whereas
# nothing rotates this log.
echo "$(ts) ensure-up: FAILED - copilot-api still not listening on $port - machine now: $(machine_state)"
# If the agent really was booted out and never re-registered, `print` does not
# return fields - it fails with 'Could not find service'. That failure IS the
# diagnosis, so it must not be swallowed by the field filter.
lp_raw="$("$LC_CMD" print "$service" 2>&1)"
lp_fields="$(printf '%s\n' "$lp_raw" | grep -E '(^|[^a-z])(state|runs|pid|last exit code) =' | tr -s ' \t' ' ' | paste -sd'|' -)"
if [ -n "$lp_fields" ]; then
	echo "$(ts) ensure-up: launchd believes:$lp_fields"
else
	echo "$(ts) ensure-up: launchd has NO record of $service - $(printf '%s' "$lp_raw" | tr '\n' ' ' | cut -c1-200)"
fi
echo "$(ts) ensure-up: last 20 lines of $proxy_log follow"
tail -20 "$proxy_log" 2>&1 | sed 's/^/    | /'
exit 1
