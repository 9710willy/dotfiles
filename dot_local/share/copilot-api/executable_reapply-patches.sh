#!/bin/bash
# Re-apply the local copilot-api patches after an npm upgrade wipes them.
#
# The patches live in the server bundle only. Its filename contains a content
# hash, so it changes every release: find it, never hard-code it.
#
# Current patch set (see the LOCAL PATCH comments in the bundle for detail):
#   (2)+(4)  replace encrypted_content blobs the backend can no longer decrypt,
#            walking every value so nested replacement_history is reached
#   (3)+(5)  recovery ladder, REWRITTEN 2026-08-13: reads the upstream error
#            body first and retries only when it names an encrypted-content
#            failure ("could not be decrypted/verified/decoded/parsed") - never
#            on bare HTTP 400. Rejected compaction items are replaced in place
#            with a visible note (never spliced). Per-session recovery memory
#            pre-applies stages a session already needed (bounded, 1h TTL).
#   (6)      replace the "<|channel|>analysis" harmony marker Copilot blocks
#   (7)      scrub-WARN dedup: the req id is a content hash of the last user
#            message, so one agentic turn repeats a byte-identical WARN per
#            round trip; log only when the (session, count) pair changes
#   DIAGNOSTIC on upstream 400: log the upstream message plus the JSON paths of
#            remaining blob-shaped strings. Payload dump is opt-in via
#            COPILOT_API_DUMP_BLOCKED=1, written 0600 and chmod'd 0600 to cover
#            a pre-existing dump.
# Retired:  (1) empty tool descriptions - upstream ships
#            fillEmptyNamespaceToolDescriptions as of 2.1.2.
# Checked against 2.2.7 (2026-08-19): nothing else can be retired. The pristine
#            2.2.7 bundle has no fernet/staleness handling, no retry on a
#            decrypt-failure 400, and no "<|channel|>analysis" filter, so (2)-(7)
#            and the diagnostic all still have to be carried forward. Upstream did
#            not touch src/services/copilot/create-responses.ts between 2.1.8 and
#            2.2.7, so the 2.1.8 diff applied to 2.2.7 with --fuzz=0 unchanged.
#
# Usage: reapply-patches.sh [path-to-diff]
# With no argument it picks the newest local-patches-*.diff next to this script.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# Moved off /opt/homebrew on 2026-08-21. copilot-api used to live in the global
# node_modules of brew's `node`, which is installed only as a DEPENDENCY of
# prettierd and yaml-language-server - so an unrelated `brew upgrade` could
# replace the runtime under the patched bundle without warning. It now has its
# own prefix that brew never touches, run by mise's node 24 (the version
# ~/.config/mise/config.toml already pins).
dist="$HOME/.local/opt/copilot-api/node_modules/@jeffreycao/copilot-api/dist"
service="gui/$(id -u)/com.willee1.copilot-api"

# Split out of the assignment on purpose. As `diff_file="${1:-$(ls ... | head -1)}"`
# the substitution runs inside the assignment, so when the glob matches nothing
# `ls` exits non-zero, pipefail propagates it, and `set -e` aborts the script
# BEFORE the guard below can print anything - making its error message dead code
# in exactly the situation it exists for.
diff_file="${1:-}"
[ -n "$diff_file" ] || diff_file="$(ls -t "$here"/local-patches-*.diff 2>/dev/null | head -1 || true)"
[ -f "$diff_file" ] || {
  echo "ERROR: no patch diff found in $here"
  exit 1
}

# Same class as diff_file above: `grep -v` on empty input exits 1, so without
# `|| true` this aborts before its own guard runs.
bundle="$(ls "$dist"/server-*.js 2>/dev/null | grep -v '\.map$' | head -1 || true)"
[ -n "$bundle" ] || {
  echo "ERROR: no server bundle in $dist"
  exit 1
}
version="$(node -p "require('$dist/../package.json').version")"
echo "bundle:  $bundle"
echo "version: $version"
echo "diff:    $diff_file"

if grep -q "LOCAL PATCH" "$bundle"; then
  echo "already patched - nothing to do"
  exit 0
fi

# Read the API key BEFORE the first irreversible step. It used to be read after
# `patch` had rewritten the bundle and `launchctl kickstart` had restarted the
# proxy on it - and as a bare `key=$(...)` assignment, so a missing, malformed or
# key-less config.json aborted the script there under `set -e`, bypassing
# rollback() entirely and leaving a patched, unverified bundle live with no
# health line. `node -p` also PRINTS "undefined" and exits 0 when the key is
# absent, so a non-empty result is not enough on its own.
key="$(node -p "require('$here/config.json').auth.apiKeys[0]" 2>/dev/null || true)"
if [ -z "$key" ] || [ "$key" = "undefined" ] || [ "$key" = "null" ]; then
  echo "ERROR: no usable auth.apiKeys[0] in $here/config.json - refusing to patch,"
  echo "because the health check after patching could not run without it."
  exit 1
fi

backup="$here/$(basename "$bundle").bak-$(date +%Y-%m-%dT%H%M%S)"
cp -p "$bundle" "$backup"

# Defined before the first irreversible step rather than after it: from here on
# every failure has to be able to put the old bundle back.
rollback() {
  echo "ERROR: $1 - restoring $backup"
  cp -p "$backup" "$bundle"
  launchctl kickstart -k "$service" || true
  exit 1
}

# One definition so the dry run and the real apply cannot drift apart - a dry run
# that proved a different set of flags is worse than no dry run at all.
# --fuzz=0: a hunk that only applies with fuzz has landed somewhere the author
# did not intend, which is worse than not applying at all.
apply_patch() { patch "$@" --fuzz=0 --forward -p0 -l "$bundle" <"$diff_file"; }

if ! apply_patch --dry-run >/dev/null 2>&1; then
  echo "ERROR: $diff_file does not apply cleanly to $version."
  echo "Port the patches by hand against the LOCAL PATCH comments, then save a fresh diff:"
  echo "  diff -u <pristine-bundle> $bundle > $here/local-patches-$version.diff"
  exit 1
fi
apply_patch

node --check "$bundle" || rollback "patched bundle fails node --check"

# Behavioural smoke test, not just a marker grep: load the patched functions and
# assert they actually do something. A bundle where the hunks applied to dead
# code passes `node --check` and a marker grep, but fails this.
node --input-type=commonjs -e "
const fs = require('node:fs');
const src = fs.readFileSync('$bundle', 'utf8');
const start = src.indexOf('const STALE_ENCRYPTED_CONTENT_MS');
const end = src.indexOf('const createResponses = async');
if (start < 0 || end < 0 || end <= start) { console.error('patched region not found'); process.exit(1); }
const tmp = '$here/.smoke-$$.cjs';
fs.writeFileSync(tmp, src.slice(start, end) +
  ';module.exports={neutralizeAnalysisChannelMarkers,scrubStaleEncryptedContent,walkEncryptedContent,shouldLogScrubWarn,STALE_ENCRYPTED_CONTENT_MS,STALE_CLOCK_QUANTUM_MS};');
try {
  const m = require(tmp);
  const marker = { input: [{ type: 'message', content: [{ type: 'input_text', text: '<|channel|>analysis<|message|>hi' }] }] };
  if (m.neutralizeAnalysisChannelMarkers(marker) !== 1) { console.error('marker neutraliser did nothing'); process.exit(1); }
  const stale = Buffer.alloc(9); stale[0] = 0x80;
  stale.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 1000) - 48 * 3600), 1);
  const blob = stale.toString('base64') + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const nested = { input: [{ type: 'compaction', encrypted_content: 'keep',
    replacement_history: [{ type: 'agent_message', content: [{ type: 'encrypted_content', encrypted_content: blob }] }] }] };
  if (m.scrubStaleEncryptedContent(nested) !== 1) { console.error('stale scrub did not reach replacement_history'); process.exit(1); }
  const dedup = [m.shouldLogScrubWarn('sA', 148), m.shouldLogScrubWarn('sA', 148), m.shouldLogScrubWarn('sA', 143), m.shouldLogScrubWarn('sB', 148)];
  if (String(dedup) !== 'true,false,true,true') { console.error('scrub WARN dedup misbehaves: ' + dedup); process.exit(1); }
  // The staleness clock is quantized to STALE_CLOCK_QUANTUM_MS so the stale set
  // changes at most once per hour instead of on every request (a continuously
  // moving boundary rewrote the prompt prefix mid-turn and dropped those
  // sessions to ~31% cache hit rate). Flooring can only DELAY a scrub, by at
  // most one quantum, so the window must leave room for it: window + quantum
  // must stay at or under the backend's ~11h decrypt limit, or a blob the
  // backend can no longer decrypt gets sent and wedges the session.
  if (typeof m.STALE_CLOCK_QUANTUM_MS !== 'number' || m.STALE_CLOCK_QUANTUM_MS <= 0) {
    console.error('STALE_CLOCK_QUANTUM_MS missing - staleness clock is not quantized'); process.exit(1); }
  if (m.STALE_ENCRYPTED_CONTENT_MS + m.STALE_CLOCK_QUANTUM_MS > 11 * 60 * 60 * 1e3) {
    console.error('window + quantum exceeds the ~11h backend decrypt limit'); process.exit(1); }
  // A blob comfortably inside the window must NOT be scrubbed, or every long
  // session pays a needless prefix break and loses reasoning continuity.
  const fresh = Buffer.alloc(9); fresh[0] = 0x80;
  fresh.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 1000) - 2 * 3600), 1);
  const freshPayload = { input: [{ type: 'reasoning', encrypted_content: fresh.toString('base64') + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }] };
  if (m.scrubStaleEncryptedContent(freshPayload) !== 0) {
    console.error('a 2h-old blob was scrubbed - window is far too aggressive'); process.exit(1); }
  console.log('smoke test: marker neutraliser, nested stale scrub, WARN dedup, quantized clock (window '
    + m.STALE_ENCRYPTED_CONTENT_MS / 3.6e6 + 'h + quantum ' + m.STALE_CLOCK_QUANTUM_MS / 3.6e6 + 'h), and fresh-blob passthrough all fire');
} finally { fs.rmSync(tmp, { force: true }); }
" || rollback "patched bundle fails the behavioural smoke test"

launchctl kickstart -k "$service" || rollback "could not restart $service"
code=000
for _ in $(seq 1 15); do
  # Key goes in via --config on stdin so it never appears in curl's argv,
  # where a root-level EDR/audit agent would capture it.
  # --connect-timeout/--max-time are what make the 15-attempt cap a real ~30s
  # deadline. curl has NO default transfer timeout, so a proxy that binds 4141
  # but wedges before responding - precisely the state a bad patch produces, and
  # what this check exists to catch - would block attempt 1 forever, never reach
  # rollback, and leave the broken bundle live.
  # `|| code=000` is required: under `set -e` a curl connect failure (exit 7,
  # normal while the service is still binding 4141) aborted this script before
  # the retry loop could run. Observed 2026-08-19 upgrading to 2.2.7: the bundle
  # was patched, smoke-tested and healthy, but the script exited 7 with no
  # health line and no rollback.
  code="$(printf 'header = "Authorization: Bearer %s"\nurl = "http://127.0.0.1:4141/v1/models"\n' "$key" |
    curl -s --connect-timeout 2 --max-time 5 -o /dev/null -w "%{http_code}" --config -)" || code=000
  [ "$code" = "200" ] && break
  sleep 2
done
[ "$code" = "200" ] || rollback "proxy unhealthy (HTTP $code) after patching"
echo "proxy health: $code"
echo "patched $version and verified. Backup: $backup"
