#!/bin/bash
# Re-apply the local copilot-api patches after an npm upgrade wipes them.
#
# The patches live in the server bundle only. Its filename contains a content
# hash, so it changes every release: find it, never hard-code it.
#
# Current patch set (see the LOCAL PATCH comments in the bundle for detail):
#   (2)+(4)  replace encrypted_content blobs the backend can no longer decrypt,
#            walking every value so saved recovery source windows are covered
#   (3)+(5)  recovery ladder, REWRITTEN 2026-08-13: reads the upstream error
#            body first and retries only when it names an encrypted-content
#            failure ("could not be decrypted/verified/decoded/parsed") - never
#            on bare HTTP 400. A real compaction response binds its encrypted
#            value to the readable request window that ended in
#            compaction_trigger. Rejected wrappers restore from that bounded
#            cache. A cache miss leaves the request unchanged and fails visibly.
#            Per-session recovery memory pre-applies stages a session already
#            needed (bounded, 1h TTL).
#   (6)      replace the "<|channel|>analysis" harmony marker Copilot blocks
#   (7)      scrub-WARN dedup: the req id is a content hash of the last user
#            message, so one agentic turn repeats a byte-identical WARN per
#            round trip; log only when the (session, count) pair changes
#   (8)      ADDED 2026-09-05, the fix for the 2026-09-05 wedge. Two hunks.
#            (a) rememberedRecoveryStages refreshes expiresAt on read, making the
#            recovery memory an IDLE timeout instead of a lifetime. Root cause:
#            the ladder armed 3 stages at 09:30:52Z, the memory died at
#            10:30:52Z on the fixed 60 min TTL, and the request 73 SECONDS later
#            at 10:32:05Z - still inside ONE 61.59 min Codex turn - shipped the
#            120 reasoning blobs stage 1 had been dropping for 176 requests.
#            (b) an in-stream `response.failed` whose message matches
#            RECOVERABLE_400 now arms IN_STREAM_ARM_STAGES (2) for the session.
#            createHttpResponses throws only on !response.ok, so a 200-then-
#            response.failed never reaches the ladder's catch and the session
#            could never re-learn its stages. Bytes are already on the wire, so
#            this arms rather than retries - it costs one turn, not the session.
#            Both hunks only ever cause MORE scrubbing, never less, and neither
#            touches isStaleFernet, the 10h window or the 1h quantum, so the
#            replacement boundary does not move and prompt caching is unchanged
#            (verified 95.0-100% after, against a 91.3-99.9% baseline).
#            Replayed against the wedged session's real timestamps from
#            copilot-api.sqlite: lifetime TTL leaves 2 requests with an empty
#            memory, idle TTL leaves 0; largest real gap was 1.33 min of 60.
#            NOT an age fix, and it does not need to be: the request that wedged
#            shipped 120 reasoning blobs that were 1.03h old (one turn, started
#            09:30:30.514Z). No age rule of any kind would have prevented it.
#            (b2) WIDENED 2026-09-05, after (b) failed to fire on a real wedge.
#            The LOG was gated on RECOVERABLE_400 as well as the arming, so a
#            response.failed with any other message left NO trace at all - which
#            is what happened at 13:51:30Z: the arm fired 0 times and nothing
#            said why. Logging is now unconditional (code + message, never the
#            payload); arming is still gated. Debug logging is off and stream
#            chunks are logged only under debug, so that message could not be
#            recovered after the fact.
#            WHAT (b2) THEN REVEALED, and it matters: the real event is
#            `code=? message="(no message)"` - no error object at all. Observed
#            4x at 20:47:45Z on one content-hash request id, i.e. Codex retried
#            identical bytes 4 times. So (b) can NEVER arm on this shape, and the
#            failure is not decrypt, not content-filter, not context-length. That
#            session then RECOVERED on its own (9 requests after, still running):
#            cost was one turn, not the session. Do NOT "fix" this by arming on
#            an empty-error failure - the session self-recovers, so arming would
#            drop its reasoning blobs for the rest of the session and buy
#            nothing. Startup is not a token race either: start.ts awaits
#            setupCopilotToken() and cacheModels() before the server listens.
#   (10)     ADDED 2026-09-05. Persist the recovery memory across restarts.
#            WHY: recoveryMemory is a plain in-process Map and this machine
#            sleeps. Measured 2026-09-05: 10 proxy starts, launchd runs=14,
#            because watchdog.sh restarts on wake ("no tick for 5202s (system
#            slept) - upstream sockets likely dead"). Hunk (8a) stopped the map
#            emptying by EXPIRY; this stops it emptying by RESTART, which is the
#            only remaining route from a wake-restart to a PERMANENT wedge - a
#            session that already armed stages loses them, and per (b2) it cannot
#            always re-learn them.
#            Three hunks: hydrate on module load, persist on arming (forced),
#            persist on the (8a) read-refresh (throttled 30s, else it would be a
#            disk write per request). File is APP_DIR/recovery-memory.json at
#            0600 (it holds session ids), written tmp+rename so a crash cannot
#            leave a torn file, and every I/O path swallows its own errors - a
#            disk problem must never surface as a failed request.
#            KEEP THE FILE PATH LAZY. The smoke test slices this region out of
#            the bundle WITHOUT its imports, so an eager
#            `const F = path.join(PATHS.APP_DIR, ...)` at module scope kills the
#            whole smoke test on require. There is an assertion for this.
#            No cache impact: nothing here touches isStaleFernet, the window, the
#            quantum, or which bytes get forwarded.
#            OPERATIONAL NOTE that still applies: resetting the bundle to
#            pristine before running this script makes its rollback restore
#            PRISTINE, i.e. an unpatched live proxy (that happened at 09:22).
#            Snapshot the working patched bundle first, and check
#            `lsof -nP -iTCP:4141 -sTCP:ESTABLISHED` is empty before restarting.
#   (9)      ADDED 2026-09-05. OBSERVE ONLY - counts, never mutates, so the
#            forwarded bytes and the prompt prefix are untouched. Reads
#            internal_chat_message_metadata_passthrough.turn_id, a UUIDv7 whose
#            top 48 bits are the turn's start in epoch-ms, and logs one
#            LOCAL DIAGNOSTIC line when a live request carries an item-level
#            encrypted_content stamped older than the window. It has to run at
#            the boundary in handleResponses, one line before
#            sanitizeUnsupportedInputFields, which deletes that stamp 17 lines
#            before createResponses gets the payload. Dedup reuses
#            shouldLogScrubWarn under a ":stamp" key, so no new state and no
#            collision with the fernet scrub's entry for the same session; the
#            hour-quantized clock caps it at one line per session per hour.
#
#            WHY OBSERVE AND NOT DROP. This is the part to read before "fixing"
#            the blind spot. The proactive age scrub is indeed blind to ~97% of
#            carriers: only the {type:"encrypted_content"} PART shape is a Fernet
#            token, while a reasoning item's own encrypted_content is opaque
#            ciphertext (7.979 bits/byte from byte 0, no version byte), so
#            fernetMintedMs returns null and isStaleFernet is false. It has never
#            fired once in production: 0 "replaced N stale encrypted payload(s)"
#            lines against 4652 reactive pre-apply lines. That looks like a bug
#            and probably is not one. Measured across the 40 largest September
#            rollouts: only 2 sessions ever held a >10h stamped blob in a live
#            window, and BOTH completed with ZERO errors - 2026-09-01T05-33-24
#            shipped 90 reasoning blobs stamped 13.6h old across 11 turns, and
#            2026-09-01T05-36-00 shipped 3 at 12.36h across 60 turns. So the
#            backend's ~11h decrypt limit is NOT established for this shape, and
#            a sighted age rule would have deleted 90 blobs from a session that
#            worked perfectly. That is a regression, not a fix.
#            So: the staleness window (2)+(4) rests on an unverified premise for
#            the shape carrying nearly all the volume. Correlate this diagnostic
#            with a REAL failure before acting on it. If it keeps firing on
#            healthy sessions, that is grounds to RETIRE (2)+(4), not extend it.
#            Do not reach for a WeakMap keyed on item identity here - the age is
#            needed 17 lines later in the same request, a plain read at the
#            boundary covers it, and an identity-keyed side table fails silently
#            (returns undefined, scrub goes blind) which is the very bug class
#            this whole patch family exists to fight.
#   DIAGNOSTIC on upstream 400: log the upstream message plus the JSON paths of
#            remaining blob-shaped strings. Payload dump is opt-in via
#            COPILOT_API_DUMP_BLOCKED=1, written 0600 and chmod'd 0600 to cover
#            a pre-existing dump.
#   (11)     ADDED 2026-09-06, found by /dev-review and /simplify against 2.5.1.
#            Two fixes, both verified with a standalone repro before landing:
#            (a) reportUnrecovered was reading lastErr's upstream message AFTER
#            releaseErrorBody had already cancelled that same error's response
#            body. A cancelled body's clone() always throws (Fetch spec), so
#            readUpstreamMessage's own try/catch swallowed it and returned "",
#            silently falling back to the FIRST error's message instead of the
#            LAST one - exactly the blind spot patch (8b2) exists to close, for
#            the ladder-exhausted-on-a-400 case. Fix: capture the message inside
#            the retry loop, where it is already read once to test
#            RECOVERABLE_400, and reuse it - never re-read a released body.
#            This also removes a redundant second read/clone of the same body.
#            (b) isStaleFernet and countOldStampedEncryptedFields each computed
#            their own copy of `Math.floor(Date.now() / STALE_CLOCK_QUANTUM_MS)
#            * STALE_CLOCK_QUANTUM_MS`. Hoisted to one `quantizedNow()` so the
#            two staleness clocks cannot drift apart from a future edit to one
#            copy and not the other. No behavior change - verified against the
#            existing smoke test below (all assertions pass unmodified) plus a
#            standalone Response-based repro proving (a)'s fix.
#   (12)     ADDED 2026-09-06, same review pass as (11), on user request to fix
#            the rest rather than leave them as findings. Five more fixes:
#            (a) persistRecoveryMemory's tmp filename was `${file}.${pid}.tmp` -
#            constant per process - so two concurrent forced persists
#            (rememberRecoveryStages calls persistRecoveryMemory(true), bypassing
#            the throttle) raced the same tmp path; one write silently won, the
#            other's rename ENOENTed into the empty catch. Fixed with a
#            monotonic per-call counter in the tmp name, so concurrent persists
#            never collide - each rename now succeeds. Completion order (not
#            call order) still decides which write is the one left on disk when
#            two land close together; that residual is accepted, not fixed,
#            since serializing writes is real work for a rare event with a
#            self-healing consequence (the ladder just re-arms on the next 400).
#            (b) persistRecoveryMemory/hydrateRecoveryMemory swallowed every
#            failure with zero logging, unlike every other catch in this file -
#            a disk problem could disable patch (10)'s restart-survival forever
#            with no signal. Now warns once per process on a persist failure,
#            and on any hydrate failure other than ENOENT (a missing file on
#            first-ever startup is the normal case, not a failure).
#            (c) walkEncryptedContent, neutralizeAnalysisChannelMarkers's visit,
#            and describeRemainingBlobs's visit had no recursion-depth cap - a
#            payload nested ~5000 levels deep (not a real production shape;
#            real nesting runs a handful of levels) threw an uncaught RangeError
#            with no catch around any call site. Capped at MAX_WALK_DEPTH=500.
#            (d) the "pre-applied a recovery" and "neutralised N harmony
#            marker(s)" WARN lines had no dedup, unlike the stale-blob WARN two
#            lines above either of them - field data already showed 4652 raw
#            occurrences of the pre-apply line. Both now go through the same
#            shouldLogScrubWarn dedup, under suffixed keys so they can't
#            collide with the stale-blob WARN's own entry for the same session.
#            (e) recoveryMemory's eviction deleted the oldest-INSERTED key
#            (Map iteration order), but refresh-on-read mutated the entry in
#            place without moving it, so a session refreshed every request
#            could still be evicted before an idle one once the 64-session cap
#            is hit. Refresh now deletes-and-re-sets to move the entry to the
#            back, making the existing eviction line actually LRU.
#            Also derived IN_STREAM_ARM_STAGES from RECOVERY_STAGES.length - 1
#            instead of a bare literal 2, so a future stage inserted anywhere
#            but the end can't silently change what an in-stream failure arms
#            without this changing to match.
#            The smoke test below was also extended: it used to slice this
#            region out WITHOUT path/PATHS/fs-promises/consola, so
#            persistRecoveryMemory and hydrateRecoveryMemory always hit the
#            ReferenceError-then-empty-catch branch and "passed" regardless of
#            whether real disk I/O worked - which is how (a) and (b) shipped
#            unnoticed for a day. It now shims real bindings against an
#            isolated tmp APP_DIR and asserts a real write/read/restore round
#            trip, 0600 file mode, the concurrent-persist race, the depth cap,
#            and LRU eviction.
#            Deliberately NOT done in this pass, left as review findings: (i)
#            the retry ladder, the in-stream arm's call site, and the two
#            full-tree walks per request are still not covered by the smoke
#            test (extending the slice to include createResponses's body is
#            larger, riskier surgery on the smoke-test harness itself); (ii)
#            merging the three tree-walkers, and fusing the two full-payload
#            walks into one pass, are real but debatable simplifications, not
#            done here because doing so in code that had two subtle bugs found
#            the same day, with no test covering the merged result, is a worse
#            trade than leaving three simple walkers in place; (iii) a bare
#            (non-array-element) encrypted_content part would still walk past
#            unscrubbed - judged unreachable given the API's content-array
#            schema, not verified unreachable.
# Retired:  (1) empty tool descriptions - upstream ships
#            fillEmptyNamespaceToolDescriptions as of 2.1.2.
# Checked against 2.4.1 (2026-09-05): nothing else can be retired. The pristine
#            2.4.1 bundle still has no fernet/staleness handling, no retry on a
#            decrypt-failure 400, and no "<|channel|>analysis" filter, so (2)-(7)
#            and the diagnostic all still have to be carried forward. 2.3.9 ->
#            2.3.10 changed the server bundle only: three new models
#            (hy4-preview, grok-4.6, qwen3.8-flash), a longer "stream ended
#            without a completion event" message, and a codex tool-tip helper
#            that now targets the last USER message instead of the last message.
#            None of it touches the patched region, so the 2.3.1 diff applied
#            unchanged with --fuzz=0. local-patches-2.3.10.diff is the re-cut,
#            offset-0 version of it; the 2.3.1 diff and its pristine bundle were
#            deleted once 2.3.10 was verified live.
#            2.3.10 -> 2.3.14 adds transport-safe reasoning replay, OpenRouter
#            reasoning fields, correct custom-tool IDs, yielded-execution resume
#            tips, and empty thinking text. None touches the patched region. The
#            2.3.10 diff applied unchanged with --fuzz=0 and passed the full smoke
#            test. local-patches-2.3.14.diff is the re-cut, offset-0 version.
#            2.3.14 -> 2.4.1 (four releases: 2.3.15, 2.3.16, 2.4.0, 2.4.1) adds
#            Azure Entra auth, opencode-go x-opencode-session forwarding, token
#            usage period stats, a bundled offline codex model catalog, the
#            gpt-6-astra entry, and a Bun prompt EPIPE fix. Thirteen source files
#            changed; none is routes/responses/utils.ts,
#            routes/provider/responses/handler.ts or routes/responses/handler.ts,
#            so the patched region is untouched. The 2.3.14 diff applied
#            unchanged with --fuzz=0 (hunks land +112 lines down, body
#            byte-identical) and passed the full smoke test.
#            local-patches-2.4.1.diff is the re-cut, offset-0 version.
#            NOT fixed by this upgrade: applyResponsesApiContextManagement still
#            returns false for gpt-5.6+ (upstream 5896069, "to preserve cache
#            hits", test-covered), so compactInputByLatestCompaction never runs
#            and Codex's own compaction carriers accumulate in every request.
#            Leave that gate alone - removing it is what would cost prompt cache
#            hits. Upstream issues #309, #363 and #346 report the resulting
#            wedge; all three were closed by pointing at the README config.
#            2.4.1 -> 2.5.1 (2.4.2 skipped, no server changes worth a separate
#            bump) adds image edit/generation endpoints, provider alias routing
#            for images, a custom server listening host for the desktop app,
#            and three security fixes: stop logging OAuth tokens, refuse
#            non-loopback bindings by default, write credentials atomically.
#            Files touched include src/routes/responses/route.ts and
#            src/routes/provider/responses/route.ts (renamed at some point from
#            the .../handler.ts paths named above - same patched region, new
#            path). The 2.4.1 diff applied unchanged with --fuzz=0 (hunks land
#            +48 lines down from unrelated changes earlier in the file, body
#            byte-identical) and passed the full smoke test and live health
#            check on 2026-09-06. local-patches-2.5.1.diff is the re-cut,
#            offset-0 version; local-patches-2.4.1.diff and server-2.4.1.pristine
#            were deleted once this was verified live.
#            2.5.1 -> 2.5.3 adds a shared upstream transport lifecycle,
#            COPILOT_API_GITHUB_TOKEN support, desktop token forwarding,
#            DashScope models, preservation of unreadable config files, and a
#            one-second delay for subagent WebSocket requests after a root-agent
#            message. The transport and delay work changed createResponses:
#            `signal` became `clientSignal`, HTTP calls now use the shared
#            lifecycle, and the WebSocket branch gained the delay. Ported the
#            local HTTP recovery ladder to `clientSignal` and kept the new
#            WebSocket branch intact. The other local hunks merged unchanged.
#            local-patches-2.5.3.diff is the re-cut, offset-0 version.
#            2.5.3 -> 2.5.4 replaces the DeepSeek flash model, restores its
#            Codex code mode and tool tips, and removes the root-to-subagent
#            WebSocket delay beside createResponses. Rebased the first two
#            local hunks around the removed delay. The local behavior is
#            unchanged. local-patches-2.5.4.diff is the re-cut, offset-0
#            version.
#            2.5.4 -> 2.5.8 changes the WebSocket request preparation beside
#            createResponses. Rebased the HTTP recovery ladder after the new
#            WebSocket branch and kept the upstream request object intact.
#            The other local hunks apply unchanged with --fuzz=0.
#            local-patches-2.5.8.diff is the re-cut, offset-0 version.
#
# DO NOT SET useResponsesApiWebSocket = true. Upstream's DEFAULT IS true; this
#            setup overrides it to false in config.json on purpose, and the only
#            record of why used to be nobody's memory. In createResponses the
#            websocket branch RETURNS EARLY:
#              if (payload.stream === true && effectiveTransport === "websocket")
#                return createPooledResponsesWebSocketStream(...)
#            Everything below that line - the RECOVERABLE_400 gate, the recovery
#            ladder, and rememberRecoveryStages - is HTTP-only. Patches (2), (6)
#            and (7) still run because they sit above the branch, but (3)+(5) do
#            not, and because rememberRecoveryStages is only reached inside the
#            HTTP retry path a session can never even LEARN it needs recovery,
#            so the pre-applied shortcut dies too. All Codex/Claude traffic
#            streams, so this is not an edge case - it is all of it. Upstream's
#            own README confirms there is no safety net: "WebSocket failures are
#            not retried automatically over HTTP." Failure mode is silent: no
#            error, no log line, just wedged sessions on the next decrypt-failure
#            400. (Compaction requests force compactType === 1, which pins them
#            to HTTP, so only those would keep the ladder.)
#            To ever enable it, the patched block must first be moved ABOVE the
#            websocket branch. That is real work, not a flag.
#            Checked against 2.4.1 on 2026-09-05; the early return is still there.
#
# Usage: reapply-patches.sh [path-to-diff]
# With no argument it picks the patch for the installed package version.
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

bundle="$(find "$dist" -maxdepth 1 -type f -name 'server-*.js' -print -quit 2>/dev/null || true)"
[ -n "$bundle" ] || {
  echo "ERROR: no server bundle in $dist"
  exit 1
}
version="$(node -p "require('$dist/../package.json').version")"
diff_file="${1:-$here/local-patches-$version.diff}"
[ -f "$diff_file" ] || {
	echo "ERROR: no patch diff found for installed version $version: $diff_file"
	exit 1
}
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
const fsp = require('node:fs/promises');
const pathMod = require('node:path');
const src = fs.readFileSync('$bundle', 'utf8');
const start = src.indexOf('const STALE_ENCRYPTED_CONTENT_MS');
const end = src.indexOf('const createResponses = async');
if (start < 0 || end < 0 || end <= start) { console.error('patched region not found'); process.exit(1); }
const tmp = '$here/.smoke-$$.cjs';
// Real path/fs-promises/PATHS/consola, not stubs that always succeed: patch (10)'s
// persist/hydrate previously ran against undefined bindings here, so every call
// hit the ReferenceError-then-swallowed-by-catch branch and 'passed' regardless
// of whether real disk I/O worked. APP_DIR is an isolated tmp dir, never the real
// one, so this can never race the live recovery-memory.json.
const shim = 'const { createHash } = require(\'node:crypto\');\nconst path = require(\'node:path\');\nconst fs\$1 = require(\'node:fs/promises\');\nconst PATHS = { APP_DIR: require(\'node:fs\').mkdtempSync(require(\'node:os\').tmpdir() + \'/copilot-smoke-\') };\nconst consola = { warn: function () {} };\n';
fs.writeFileSync(tmp, shim + src.slice(start, end) +
  ';module.exports={captureCompactionSource,compactionHistoryCache,rememberCompactionHistory,rememberCompactionResult,rememberCompactionStream,restoreUnusableCompactionHistory,neutralizeAnalysisChannelMarkers,scrubStaleEncryptedContent,walkEncryptedContent,describeRemainingBlobs,shouldLogScrubWarn,STALE_ENCRYPTED_CONTENT_MS,STALE_CLOCK_QUANTUM_MS,MAX_WALK_DEPTH,recoveryMemory,rememberedRecoveryStages,rememberRecoveryStages,RECOVERY_MEMORY_TTL_MS,RECOVERY_MEMORY_MAX_SESSIONS,IN_STREAM_ARM_STAGES,RECOVERABLE_400,countOldStampedEncryptedFields,uuid7MintedMs,persistRecoveryMemory,hydrateRecoveryMemory,recoveryHydration,recoveryMemoryFile};');
(async () => {
try {
  const m = require(tmp);
  await m.recoveryHydration;
  const marker = { input: [{ type: 'message', content: [{ type: 'input_text', text: '<|channel|>analysis<|message|>hi' }] }] };
  if (m.neutralizeAnalysisChannelMarkers(marker) !== 1) { console.error('marker neutraliser did nothing'); process.exit(1); }
  const stale = Buffer.alloc(9); stale[0] = 0x80;
  stale.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 1000) - 48 * 3600), 1);
  const blob = stale.toString('base64') + 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const nested = { input: [{ type: 'agent_message', content: [{ type: 'encrypted_content', encrypted_content: blob }] }] };
  if (m.scrubStaleEncryptedContent(nested) !== 1) { console.error('stale scrub did not reach nested content'); process.exit(1); }
  const history = [{ type: 'message', role: 'assistant', content: [{ type: 'output_text', text: 'PRESERVED_ASSISTANT' }] }];
  const source = m.captureCompactionSource({ input: history.concat({ type: 'compaction_trigger' }) });
  if (JSON.stringify(source) !== JSON.stringify(history)) { console.error('compaction source capture failed'); process.exit(1); }
  if (!m.rememberCompactionHistory('cache-key', source)) { console.error('compaction source was not cached'); process.exit(1); }
  const later = { input: [{ type: 'message', role: 'developer', content: [{ type: 'input_text', text: 'DUPLICATE' }] }, { type: 'compaction', encrypted_content: 'cache-key' }] };
  if (m.restoreUnusableCompactionHistory(later) !== 1 || JSON.stringify(later.input) !== JSON.stringify(history)) {
    console.error('later-request compaction recovery failed'); process.exit(1); }
  const missing = { input: [{ type: 'compaction', encrypted_content: 'missing-key' }] };
  const missingBefore = JSON.stringify(missing);
  if (m.restoreUnusableCompactionHistory(missing) !== 0 || JSON.stringify(missing) !== missingBefore) {
    console.error('missing compaction history did not fail closed'); process.exit(1); }
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
  // Patch (8), added 2026-09-05. The recovery memory must be an IDLE timeout, not
  // a lifetime. The 2026-09-05 wedge: the ladder armed 3 stages at 09:30:52Z, the
  // memory expired at 10:30:52Z on the fixed TTL, and the request at 10:32:05Z -
  // 73 SECONDS later, inside a single 61.59 min Codex turn - shipped the 120
  // reasoning blobs stage 1 had been dropping for the previous 176 requests.
  // Replayed against that session's real timestamps from copilot-api.sqlite:
  // lifetime TTL leaves 2 requests with an empty memory, idle TTL leaves 0
  // (largest real gap between its requests was 1.33 min). Assert the refresh so
  // this cannot silently regress to a lifetime again.
  m.rememberRecoveryStages('smoke-idle', 3);
  const entry = m.recoveryMemory.get('smoke-idle');
  if (!entry) { console.error('rememberRecoveryStages stored nothing'); process.exit(1); }
  entry.expiresAt = Date.now() + 60 * 1e3;         // simulate 59 of 60 minutes gone
  if (m.rememberedRecoveryStages('smoke-idle') !== 3) {
    console.error('a live recovery entry did not return its stages'); process.exit(1); }
  if (m.recoveryMemory.get('smoke-idle').expiresAt - Date.now() < 59 * 60 * 1e3) {
    console.error('recovery memory is a LIFETIME timeout - reading it must refresh expiresAt,'
      + ' or a Codex turn longer than the TTL wedges the session'); process.exit(1); }
  // An entry that really has expired must still be dropped: refresh-on-read may
  // only extend a LIVE entry, never resurrect a dead one.
  m.rememberRecoveryStages('smoke-dead', 2);
  m.recoveryMemory.get('smoke-dead').expiresAt = Date.now() - 1;
  if (m.rememberedRecoveryStages('smoke-dead') !== 0 || m.recoveryMemory.has('smoke-dead')) {
    console.error('an expired recovery entry was resurrected by refresh-on-read'); process.exit(1); }
  // The in-stream arm must exist and must reuse the ladder's own gate, so a
  // content filter or a missing-parameter 400 arms nothing.
  if (!(m.IN_STREAM_ARM_STAGES > 0)) {
    console.error('IN_STREAM_ARM_STAGES missing - an in-stream response.failed cannot arm recovery'); process.exit(1); }
  // NOTE: this whole block is inside a double-quoted shell string, so it must not
  // contain a double quote. Keep every JS string single-quoted.
  const arms = (msg) => m.RECOVERABLE_400.test(msg);
  if (!arms('The encrypted content for item rs_x could not be decrypted or parsed')
    || !arms('encrypted content could not be verified')
    || arms('Request blocked.')
    || arms('Missing required parameter: input[3].encrypted_content')) {
    console.error('RECOVERABLE_400 gate misbehaves - the in-stream arm would fire on the wrong failures'); process.exit(1); }
  m.recoveryMemory.delete('smoke-idle');
  // Patch (9), added 2026-09-05. OBSERVE ONLY: it must count and never mutate.
  // The whole point is that we do NOT act on stamped age yet - a live request
  // carrying 90 blobs stamped 13.6h old completed 11 turns with zero errors, so
  // the ~11h limit is unproven for this shape. If this ever starts mutating, it
  // silently deletes working context and rewrites the prompt prefix.
  const oldMs = Date.now() - 12 * 3.6e6;
  const hex = Math.floor(oldMs).toString(16).padStart(12, '0');
  const oldTid = hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-7000-8000-000000000000';
  if (m.uuid7MintedMs(oldTid) === null) {
    console.error('uuid7MintedMs cannot decode a v7 turn_id - the stamped-age probe is blind'); process.exit(1); }
  const obsPayload = { input: [{ type: 'reasoning', encrypted_content: 'x'.repeat(200),
    internal_chat_message_metadata_passthrough: { turn_id: oldTid } }] };
  const snapshot = JSON.stringify(obsPayload);
  const obs = m.countOldStampedEncryptedFields(obsPayload);
  if (!obs || obs.total !== 1 || obs.droppable !== 1) {
    console.error('countOldStampedEncryptedFields missed a 12h-old stamped reasoning blob'); process.exit(1); }
  if (JSON.stringify(obsPayload) !== snapshot) {
    console.error('patch (9) MUTATED the payload - it is observe-only and must never remove anything'); process.exit(1); }
  const freshTid = Math.floor(Date.now() - 6e5).toString(16).padStart(12, '0');
  const freshPayload2 = { input: [{ type: 'reasoning', encrypted_content: 'x'.repeat(200),
    internal_chat_message_metadata_passthrough: { turn_id: freshTid.slice(0, 8) + '-' + freshTid.slice(8, 12) + '-7000-8000-000000000000' } }] };
  if (m.countOldStampedEncryptedFields(freshPayload2) !== null) {
    console.error('a 10-minute-old stamped blob was reported as old'); process.exit(1); }
  // The smoke-idle/smoke-dead cases above fired their own fire-and-forget
  // forced persists. Drain those before the round-trip checks below start
  // their own writes, or an earlier still-in-flight write can complete after
  // - and clobber - a later one (the exact nondeterminism the persist/hydrate
  // checks below exist to catch, so it must not leak into their own setup).
  await new Promise((resolve) => setTimeout(resolve, 300));
  // Patch (10), added 2026-09-05: the recovery memory is persisted across
  // restarts because this machine sleeps and watchdog.sh restarts on wake (10
  // proxy starts, launchd runs=14, on 2026-09-05 alone).
  // FIXED 2026-09-06: path/PATHS/fs-promises/consola are shimmed above now
  // (isolated tmp APP_DIR - never the real one), so this exercises real disk
  // I/O instead of only proving the ReferenceError-from-undefined-bindings
  // path swallows itself, which is all it did before and is how two real bugs
  // (the tmp-filename race below, and no log line on a real failure) shipped
  // and passed this smoke test unnoticed.
  if (typeof m.recoveryMemoryFile !== 'function') {
    console.error('recoveryMemoryFile must be a lazy function, not an eager const'); process.exit(1); }
  m.recoveryMemory.clear();
  m.rememberRecoveryStages('smoke-persist', 2);
  await m.persistRecoveryMemory(true);
  const persistedRaw = await fsp.readFile(m.recoveryMemoryFile(), 'utf8');
  const persisted = JSON.parse(persistedRaw);
  if (persisted.version !== 2 || !Array.isArray(persisted.sessions) || persisted.sessions.length !== 1 || persisted.sessions[0][0] !== 'smoke-persist' || persisted.sessions[0][1].stages !== 2) {
    console.error('persistRecoveryMemory did not write the expected entry: ' + persistedRaw); process.exit(1); }
  if (!Array.isArray(persisted.compactions) || persisted.compactions.length !== 1) {
    console.error('persistRecoveryMemory did not write the compaction cache: ' + persistedRaw); process.exit(1); }
  const persistedMode = (await fsp.stat(m.recoveryMemoryFile())).mode & 511;
  if (persistedMode !== 384) {
    console.error('recovery-memory file is not 0600 (got 0' + persistedMode.toString(8) + ') - it holds session ids'); process.exit(1); }
  m.recoveryMemory.clear();
  m.compactionHistoryCache.clear();
  await m.hydrateRecoveryMemory();
  const restored = m.recoveryMemory.get('smoke-persist');
  if (!restored || restored.stages !== 2) {
    console.error('hydrateRecoveryMemory did not restore what persistRecoveryMemory wrote'); process.exit(1); }
  const restarted = { input: [{ type: 'compaction', encrypted_content: 'cache-key' }] };
  if (m.restoreUnusableCompactionHistory(restarted) !== 1 || JSON.stringify(restarted.input) !== JSON.stringify(history)) {
    console.error('hydrateRecoveryMemory did not restore compaction history'); process.exit(1); }
  // FIXED 2026-09-06: two forced persists close together (two sessions arming
  // near-simultaneously - rememberRecoveryStages calls persistRecoveryMemory
  // with force:true, bypassing the throttle) used a tmp filename constant per
  // process, so both writes raced the same path: one write silently won, the
  // other's rename ENOENTed into the empty catch, sometimes leaving a torn
  // tmp file behind. Each call now gets a unique tmp name, so both renames
  // succeed and nothing is left over.
  const appDir = pathMod.dirname(m.recoveryMemoryFile());
  m.recoveryMemory.clear();
  m.rememberRecoveryStages('smoke-race-a', 1);
  const firstWrite = m.persistRecoveryMemory(true);
  m.recoveryMemory.clear();
  m.rememberRecoveryStages('smoke-race-b', 3);
  const secondWrite = m.persistRecoveryMemory(true);
  await Promise.all([firstWrite, secondWrite]);
  let raceParsed;
  try { raceParsed = JSON.parse(await fsp.readFile(m.recoveryMemoryFile(), 'utf8')); }
  catch (err) { console.error('concurrent forced persists left a torn/unreadable file: ' + err); process.exit(1); }
  if (!Array.isArray(raceParsed.sessions) || raceParsed.sessions.length !== 1 || raceParsed.sessions[0][0] !== 'smoke-race-b') {
    console.error('serialized persists did not leave the newest snapshot'); process.exit(1); }
  const leftoverTmp = fs.readdirSync(appDir).filter((f) => f.indexOf('.tmp') >= 0);
  if (leftoverTmp.length > 0) {
    console.error('concurrent forced persists left orphaned tmp file(s): ' + leftoverTmp); process.exit(1); }
  m.recoveryMemory.clear();
  m.hydrateRecoveryMemory().catch(() => {
    console.error('hydrateRecoveryMemory rejected - a missing or corrupt file must be survivable'); process.exit(1); });
  // FIXED 2026-09-06: walkEncryptedContent, neutralizeAnalysisChannelMarkers
  // and describeRemainingBlobs had no recursion-depth cap. A payload nested
  // ~5000 levels deep (real production nesting is a handful of levels; this
  // is not a shape that occurs naturally) threw an uncaught RangeError with
  // no catch around any of these call sites.
  if (typeof m.MAX_WALK_DEPTH !== 'number' || m.MAX_WALK_DEPTH <= 0) {
    console.error('MAX_WALK_DEPTH missing - the tree-walkers have no recursion cap'); process.exit(1); }
  let deepNode = 'leaf';
  for (let i = 0; i < 5000; i++) deepNode = { child: deepNode };
  const deepPayload = { input: [deepNode] };
  m.scrubStaleEncryptedContent(deepPayload);
  m.neutralizeAnalysisChannelMarkers(deepPayload);
  m.describeRemainingBlobs(deepPayload);
  // FIXED 2026-09-06: recoveryMemory's eviction deletes the oldest-INSERTED
  // key (Map iteration order), but refresh-on-read mutated the entry in place
  // without moving it - so a session refreshed every request could still be
  // evicted first, ahead of a session that armed once and went idle.
  m.recoveryMemory.clear();
  for (let i = 0; i < m.RECOVERY_MEMORY_MAX_SESSIONS; i++) m.rememberRecoveryStages('lru-' + i, 1);
  m.rememberedRecoveryStages('lru-0');
  m.rememberRecoveryStages('lru-new', 1);
  if (!m.recoveryMemory.has('lru-0')) {
    console.error('LRU refresh did not protect the hot session from eviction'); process.exit(1); }
  if (m.recoveryMemory.has('lru-1')) {
    console.error('eviction did not remove the actually-oldest untouched session'); process.exit(1); }
  m.recoveryMemory.clear();
  console.log('smoke test: marker neutraliser, nested stale scrub, WARN dedup, quantized clock (window '
    + m.STALE_ENCRYPTED_CONTENT_MS / 3.6e6 + 'h + quantum ' + m.STALE_CLOCK_QUANTUM_MS / 3.6e6 + 'h), fresh-blob passthrough, '
    + 'idle-TTL recovery memory, the in-stream arm (' + m.IN_STREAM_ARM_STAGES + ' stages), the observe-only stamped-age probe, '
    + 'real restart-persistent recovery memory I/O, concurrent-persist safety, the recursion depth cap, and LRU eviction all fire');
} finally { fs.rmSync(tmp, { force: true }); }
})().catch((err) => { console.error('smoke test crashed: ' + err); process.exit(1); });
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
