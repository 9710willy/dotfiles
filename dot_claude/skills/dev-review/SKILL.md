---
name: dev-review
description: Use when finishing non-trivial feature work — frontend, backend, or full-stack — and about to merge or open a PR, and adversarial multi-perspective code review is wanted instead of a rubber stamp. Covers React/TypeScript/UI, services/APIs/persistence/concurrency, and the cross-cutting complexity, craft, and testing lenses. Not for tiny one-line changes or pure config/docs.
---

# dev-review

Adversarial code review. The orchestrator inspects the diff, dispatches one parallel agent per relevant lens — each anchored to engineers famous for software that *runs*, not for talking about software — and aggregates everything into one report grouped by severity.

Replaces the former `FD-review` and `BD-review`. Frontend, backend, and full-stack all run through here; the lens table decides which perspectives apply.

## When to use

- Before merging a feature branch or opening a PR
- After non-trivial UI / React refactors, or service / persistence / concurrency changes
- When you want adversarial review, not validation

## When NOT to use

- Tiny one-line changes (overkill)
- Pure infra / config / docs
- Every commit — it's expensive. Reserve for end-of-feature review.

## Inputs

`$ARGUMENTS` — optional. Any of:
- PR number: `#1234` or `1234`
- Branch name: `feat/foo`
- Diff range: `main..HEAD`
- A scope hint: `frontend`, `backend` (forces the lens set instead of inferring from the diff)
- Empty → current branch's diff vs the main branch (uncommitted + commits ahead)

## Why the prompts look like this

Do not soften the lens prompts when editing this skill. "Review like a great engineer" returns the *average* of all engineering writing — Clean Code, Medium listicles, pattern worship, X engagement-bait. The prompts fight that centroid with three forces. Keep all three:

1. **Anchored to builders.** Each lens is a named person famous for software that runs (a compiler, a kernel, `java.util`, SQLite, React's reconciler, QuickCheck) — not for methodology. Their real artifacts are named in the prompt so the model anchors on artifact-fame, not quotation-fame.
2. **The slop is named.** Each lens explicitly names the cargo-cult it will drift toward, and is ordered to reject it. Naming the bullshit is what pulls the agent off the centroid.
3. **Output discipline.** Every finding must quote the code, cite a named principle, and state a concrete consequence — three gates a generic vibe cannot pass.

**When adding principles to a lens, add them to HOW THEY THINK — not to FLAG.** The FLAG list is the finding budget. More principles should sharpen judgment; more flag categories just produce more nits, which is the slop this skill exists to kill.

## Execution checklist

Use `TodoWrite` to track:

- [ ] **Resolve scope**: get `git diff --stat <range>`, the changed-file list, and commit messages. You do NOT need the full diff — each agent fetches its own (see Dispatch pattern). Read enough of it to select lenses. If the diff exceeds ~3000 lines, split by directory/module and run this skill once per slice.
- [ ] **Inventory tech** (if any backend/service surface): runtime version, frameworks (Spring, Quarkus, Micronaut, Node, plain), datastore, sync vs async style. Include in every agent's context.
- [ ] **Inspect & select lenses**: from the diff, decide which lenses have real surface area (see Lens selection).
- [ ] **Dispatch all selected agents in PARALLEL** in a single message. Each gets the dispatch prompt below with its own lens file path.
- [ ] **Aggregate**: deduplicate, group by severity, tag by lens.
- [ ] **Output the report** in the format below.

## Lens selection

Lens files live in `~/.claude/skills/dev-review/references/lenses/`. Pass the absolute path; the agent reads its own lens.

**Always dispatch** — there is always code:

| Lens | File |
|---|---|
| Complexity (Ousterhout) | `complexity.md` |
| Craft, errors & change hygiene (Carmack + Linus) | `craft.md` |
| Testing & verification (Hughes + Wilson + Bernhardt) | `testing.md` |

**Frontend** — dispatch when the diff has surface for them:

| Lens | File | Dispatch when the diff touches |
|---|---|---|
| React internals | `react.md` | `.jsx`/`.tsx`, hooks, components, context, React APIs |
| Compiler / build / perf | `build-perf.md` | rendering, data fetching, dependencies, bundle/build config, lists |
| Type system | `types.md` | any TypeScript (`.ts`/`.tsx`) |
| Accessibility | `a11y.md` | interactive UI, forms, semantic markup |
| Design-engineering | `design-eng.md` | new or changed visible UI — layout, CSS, components |
| Frontend security | `fe-security.md` | `dangerouslySetInnerHTML`/`innerHTML`, auth/tokens, `postMessage`, URLs, new deps |

**Backend** — dispatch when the diff has surface for them:

| Lens | File | Dispatch when the diff touches |
|---|---|---|
| Language & runtime mastery | `language-runtime.md` | any server-side code (always, for a backend diff) |
| Distributed systems | `distsys.md` | concurrency, remote calls, queues, retries, caching, async |
| Data layer | `data-layer.md` | SQL, ORM, migrations, schema, transactions |
| Backend security | `be-security.md` | input handling, auth, queries, serialization, file/path, crypto, new deps |
| Performance & operability | `perf-ops.md` | hot paths, loops over data, error handling, instrumentation, resource management, deploys |

When unsure, dispatch — a lens that finds nothing costs one agent; a lens you skipped costs a missed bug. Typical counts: frontend-only PR 6–8 lenses, backend-only 6–8, full-stack 9–12. For a full-stack diff, tell each frontend lens to review only the frontend slice and each backend lens only the backend slice; the always-on three see the whole diff.

## Dispatch pattern

Send every selected agent in a SINGLE message with parallel `Agent` tool calls (`subagent_type: "general-purpose"`). Each agent's prompt is this scaffold with its lens path and the diff context filled in:

```
FIRST: Read <absolute path to the lens file>. That file IS your reviewing
lens — adopt it completely, including what it tells you not to flag. Do not
review from generic best practices; review from that lens only.

CONTEXT:
- Repo root: <absolute path>
- Range: <e.g. master...HEAD, or the PR's base...head>
- Slice you are reviewing: <whole diff | the frontend files below | the backend files below>
- Tech inventory: <runtime version, frameworks, datastore, sync/async style>
- Files in your slice: <list>
- Commit messages: <messages>

GET THE DIFF YOURSELF — first tool call after reading your lens:
`git -C <repo root> diff <range> -- <the files in your slice>`
Then Read whole files, Grep for callers, and check the dependency's source
(node_modules, the package's types) whenever a finding depends on a contract
you cannot see in the diff. A finding you verified beats a finding you
suspected: if you can confirm or kill a suspicion by reading the code, do it
before writing it up, and say in the finding what you verified.

OUTPUT DISCIPLINE — every finding MUST satisfy all three or be dropped:
1. QUOTE the offending code (the actual lines). No quote = not a finding.
2. CITE the principle by name or source ("APoSD: shallow module", "Effective
   Java Item 50: defensive copies", "DDIA Ch.7: write skew", "You Might Not
   Need an Effect", "parse, don't validate"). If you cannot name what it
   violates, it is a vibe — drop it.
3. STATE the concrete consequence ("under two concurrent requests the counter
   loses updates", "re-renders on every keystroke because the handler is
   recreated"), not a category ("performance concern").

TASTE GATE: you are judged on signal, not volume. Three real blockers beat
thirty nits. Before writing any nit, ask: would the engineer this lens is
named for bother typing it? If not, cut it. A review that is mostly nits IS
the slop this skill exists to kill.

Return findings as JSON ONLY (no prose):
{
  "findings": [
    {"severity": "blocker|major|minor|nit", "file": "path", "line": 123,
     "lens": "<lens name>", "code": "<quoted offending lines>",
     "principle": "<named principle/source>", "finding": "<consequence>",
     "suggestion": "<concrete fix>",
     "verified": "<what you actually checked, and where — file:line or package
                   path — or the word UNVERIFIED plus what you could not see>"}
  ],
  "summary": "<2 sentences: your overall read>"
}

If nothing in your lens applies, return an empty findings array and say so.
Empty is an honest answer — do NOT invent findings to look thorough.
Word budget: under 900 words.
```

## Aggregation

After all agents return:

1. Parse JSON from each (tolerate minor formatting drift).
2. Drop any finding missing a quoted `code` or a named `principle` — it failed output discipline.
3. **Resolve evidence conflicts before merging.** Two lenses often land on the same line, one having actually checked the contract and one having only inferred it. Verified beats unverified — always, regardless of severity or lens:
   - One lens verified a fact (`verified` names a file/package it read) that another only speculated about → the verified one wins. If it *kills* the other finding, the other finding is **refuted**: drop it from the report and note it in one line under Resolved, naming both lenses. Never report both sides of a settled fact.
   - Both lenses verified, and they still disagree (different valid trade-offs, e.g. `overflow: auto` vs `hidden`) → this is **disputed**, not resolvable by argument. List it once under Disputed with each lens's position and what observation would settle it. Do not average them, pick a winner, or silently drop the minority view.
   - No lens verified, and the finding hinges on an unseen contract → keep it, but mark it as unverified in the report so the human knows what to check first.
4. Merge duplicates: if two lenses raise the same finding on the same line, merge into one entry, tag both lenses, and keep the HIGHEST severity assigned by any of them.
5. Group by severity: Blocker → Major → Minor → Nit. Within severity, sort by file then line.
6. Zero nits across many lenses is a good sign, not a gap. Do not pad.

## Output format

```
# dev-review report — <target>

**Lenses run:** <list> (<N> of <M>)

## Blockers — must fix before merge
- **[Lens]** `file:line` — <consequence>
  - `<quoted code>`
  - Principle: <named> · Fix: <suggestion>

## Major — should fix
...

## Minor — worth fixing
...

## Nits — optional
...

## Disputed — lenses disagree, needs an observation
- `file:line` — **[Lens A]** <position> · **[Lens B]** <position>
  - Settled by: <the specific check that would decide it>

## Resolved — refuted by another lens
- **[Lens A]** claimed <finding>; **[Lens B]** verified <fact> at <where>. Dropped.

## Reviewer summaries
- **<Lens>**: <summary>

## Coverage
- Lenses run: N of M · Files: N · Diff: N lines
- Findings: N blocker, N major, N minor, N nit · N disputed, N refuted
```

Omit the Disputed and Resolved sections when empty. Mark any surviving finding
whose `verified` field says UNVERIFIED with "(unverified: <what to check>)" so
the human knows which claims still rest on inference.

## Notes

- Adversarial by design. "No findings" should be rare and suspicious — but a lens with genuinely nothing to say must say so, not fabricate.
- Pair with `commit-commands:commit-push-pr` after fixes.
- Adding a lens: new file in `references/lenses/`, one row in the table. Nothing else changes.
