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
service="gui/$(id -u)/com.willee1.copilot-api"
plist="$HOME/Library/LaunchAgents/com.willee1.copilot-api.plist"
ts() { date '+%Y-%m-%dT%H:%M:%S'; }
up() { lsof -nP -iTCP:4141 -sTCP:LISTEN -t >/dev/null 2>&1; }

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
lock="$HOME/.local/share/copilot-api/.ensure-up.lock"
if ! mkdir "$lock" 2>/dev/null; then
	# A crashed run must not wedge restarts forever. This script's own worst case
	# is well under a minute, so anything older than 5 minutes is a corpse.
	if [ -n "$(find "$lock" -maxdepth 0 -mmin +5 2>/dev/null)" ]; then
		echo "$(ts) ensure-up: clearing a stale lock (older than 5min)"
		rmdir "$lock" 2>/dev/null
		mkdir "$lock" 2>/dev/null || { echo "$(ts) ensure-up: lock taken by another run; skipping"; exit 0; }
	else
		echo "$(ts) ensure-up: another run is already restarting; skipping"
		exit 0
	fi
fi
trap 'rmdir "$lock" 2>/dev/null' EXIT

launchctl kickstart -k "$service" 2>/dev/null
for i in 1 2 3; do
	sleep 3
	up && exit 0
	echo "$(ts) ensure-up: not listening after kickstart (try $i)"
	launchctl kickstart "$service" 2>/dev/null
done
sleep 3
up && exit 0

echo "$(ts) ensure-up: escalating to bootout+bootstrap"
launchctl bootout "$service" 2>/dev/null
sleep 1
launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null
# RunAtLoad spawn is unreliable in this domain - kick explicitly.
launchctl kickstart "$service" 2>/dev/null
for i in 1 2 3; do
	sleep 3
	up && { echo "$(ts) ensure-up: recovered via bootstrap"; exit 0; }
done
echo "$(ts) ensure-up: FAILED - copilot-api still not listening on 4141"
exit 1
