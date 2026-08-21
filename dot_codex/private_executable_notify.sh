#!/bin/bash
# Codex notification command.
# Codex passes one JSON payload as the final command argument. Reading stdin as
# a fallback also makes this script easy to test and tolerant of future changes.

payload=""
if (($# > 0)); then
  payload="${!#}"
fi
if [[ $payload != \{* && ! -t 0 ]]; then
  payload=$(cat)
fi

event=$(printf '%s' "$payload" | jq -r '.type // .event // .hook_event_name // empty' 2>/dev/null)
cwd=$(printf '%s' "$payload" | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null)
msg=$(printf '%s' "$payload" | jq -r '."last-assistant-message" // .last_assistant_message // .message // empty' 2>/dev/null)

dir=$(basename "${cwd:-$PWD}")
case "$event" in
  approval-requested|permission-request|PermissionRequest)
    title="Codex needs you — $dir"
    body="${msg:-Waiting for approval}"
    sound="Ping"
    ;;
  *)
    title="Codex done — $dir"
    body="${msg:-Turn finished}"
    sound="Glass"
    ;;
esac

# Keep the macOS alert short and on one line.
body=${body//$'\n'/ }
body=${body:0:240}

# tmux can show the bell as window activity. The subshell hides the expected
# error when this command has no controlling terminal.
(printf '\a' >/dev/tty) 2>/dev/null || true

if [[ ${CODEX_NOTIFY_DRY_RUN:-0} == 1 ]]; then
  printf '%s\n%s\n%s\n' "$title" "$body" "$sound"
  exit 0
fi

/usr/bin/osascript - "$title" "$body" "$sound" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  display notification (item 2 of argv) with title (item 1 of argv) sound name (item 3 of argv)
end run
APPLESCRIPT

exit 0
