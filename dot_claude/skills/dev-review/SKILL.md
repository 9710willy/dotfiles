---
name: dev-review
description: Use when finishing non-trivial feature work — frontend, backend, or full-stack — and about to merge or open a PR, and adversarial multi-perspective code review is wanted instead of a rubber stamp. Covers React/TypeScript/UI, services/APIs/persistence/concurrency, and the cross-cutting complexity, craft, and testing lenses. Not for tiny one-line changes or pure config/docs.
---

# dev-review

Adversarial code review. Inspect the diff, dispatch one parallel agent per relevant lens, aggregate into one report grouped by severity.

## Input

`$ARGUMENTS` — optional. A PR number (`#1234`), branch, diff range (`main..HEAD`), or a scope hint (`frontend` / `backend` forces the lens set). Empty → current branch vs the main branch, uncommitted changes included.

## Steps

1. **Resolve scope.** Get `git diff --stat <range>`, the changed-file list, and commit messages. Do not fetch the full diff — each agent pulls its own. If the diff exceeds ~3000 lines, split by module and run this skill once per slice.
2. **Inventory tech** (if there is backend surface): runtime version, frameworks, datastore, sync vs async style. Include in every agent's context.
3. **Select lenses** from the table below. When unsure, dispatch — a lens that finds nothing costs one agent; a skipped lens costs a missed bug. Typical: 6–8 lenses for a one-sided PR, 9–12 full-stack.
4. **Invoke the workflow** (args contract below). It runs one schema-validated agent per lens in parallel, then a synthesis agent that dedupes and resolves evidence conflicts. Wait for the completion notification.
5. **Render the report** from the returned object.

## Lenses

Files live in `~/.claude/skills/dev-review/references/lenses/`. Pass the absolute path; each agent reads its own lens.

| Lens file | Dispatch when the diff touches |
|---|---|
| `complexity.md` | Always |
| `craft.md` | Always |
| `testing.md` | Always |
| `react.md` | `.jsx`/`.tsx`, hooks, components, context, React APIs |
| `build-perf.md` | Rendering, data fetching, dependencies, bundle/build config, lists |
| `types.md` | Any TypeScript |
| `a11y.md` | Interactive UI, forms, semantic markup |
| `design-eng.md` | New or changed visible UI — layout, CSS, components |
| `fe-security.md` | `innerHTML`, auth/tokens, `postMessage`, URLs, new deps |
| `language-runtime.md` | Any server-side code |
| `distsys.md` | Concurrency, remote calls, queues, retries, caching, async |
| `data-layer.md` | SQL, ORM, migrations, schema, transactions |
| `be-security.md` | Input handling, auth, queries, serialization, file/path, crypto, new deps |
| `perf-ops.md` | Hot paths, loops over data, error handling, instrumentation, resources, deploys |

## Workflow invocation

The reviewer scaffold, output schemas, and aggregation rules live in `~/.claude/skills/dev-review/references/workflow.js` — the skill's opt-in to the `Workflow` tool. Pass the absolute path. Invoke:

```
Workflow({
  scriptPath: "<absolute path to ~/.claude/skills/dev-review/references/workflow.js>",
  args: {
    repoRoot: "<absolute path>",
    range: "<e.g. main...HEAD>",
    techInventory: "<runtime, frameworks, datastore, sync/async — '' if none>",
    commits: "<commit messages>",
    lenses: [
      { name: "<file basename, e.g. craft>",
        path: "<absolute lens file path>",
        slice: "<the whole diff | the frontend files listed | the backend files listed>",
        files: ["<files in this lens's slice>"] }
    ]
  }
})
```

For a full-stack diff, frontend lenses get only the frontend files and backend lenses only the backend files; the three always-on lenses get the whole diff.

It returns `{ findings, resolved, disputed, summaries, counts, lensesRun, lensesSelected }` — findings already deduped, conflict-resolved (verified beats unverified; genuine trade-offs become `disputed`), and sorted blocker → nit, then **confidence descending**, then file, line.

## Report format

```
# dev-review report — <target>

**Lenses run:** <list> (<N> of <M>)

## Blockers — must fix before merge
- **[Lens]** `file:line` — <consequence>  ·  **conf NN**
  - `<quoted code>`
  - Principle: <named> · Fix: <suggestion>
  - Might be wrong because: <falsePositiveCase>

## Major — should fix
## Minor — worth fixing
## Nits — optional

## Disputed — lenses disagree, needs an observation
- `file:line` — **[Lens A]** <position> · **[Lens B]** <position>
  - Settled by: <the check that decides it>

## Resolved — refuted by another lens
- **[Lens A]** claimed <finding>; **[Lens B]** verified <fact> at <where>. Dropped.

## Reviewer summaries
- **<Lens>**: <summary>

**Coverage:** N lenses · N files · N diff lines · N blocker / N major / N minor / N nit
```

Omit Disputed and Resolved when empty. Append "(unverified: <whatToCheck>)" to findings with `unverified: true`. Zero nits is a good sign — do not pad.

## Confidence and the false-positive case

Every finding carries `confidence` (integer 0-100) and `falsePositiveCase` (the strongest argument that the finding is wrong). Both are enforced by the schema in `workflow.js`.

**Why a wide scale.** A two-value verdict — confirmed / plausible, verified / unverified — ties almost everything and forces the reader to eyeball the whole list. Measured on a 20-case set: a 0-100 scale separated real findings from false ones with **zero ties**, while the binary verdict tied 80% of pairs. Ranking is the entire value; a scale you only use two values of gives you none.

Watch for clumping. If reviewers pile up at 95 and 100, the scale has collapsed back to binary and the ranking is worthless — tighten the lens prompts rather than trusting the order.

**Why the false-positive case.** It is a lie detector, not a disclaimer. A reviewer that cannot argue against its own finding has not tested it — it is agreeing with itself. A `falsePositiveCase` that is vague or absent is the signal to distrust that finding regardless of its confidence.

## Label log

After rendering the report, append one JSON object per finding to `~/.claude/review-labels.jsonl`:

```json
{"ts":"<ISO8601>","target":"<range or PR>","file":"...","line":0,"lens":"...","severity":"...","confidence":0,"finding":"...","outcome":null}
```

Leave `outcome` null. When findings are later acted on, set it to `fixed`, `skipped`, or `no_change_needed`.

This is the only source of ground truth for whether the confidence numbers mean anything. Without it the scale is unfalsifiable. Do not skip it, and do not backfill outcomes by guessing.

## Editing this skill

The lens prompts fight the training-data centroid ("review like a great engineer" returns Clean Code averages). Keep their three forces: each lens is anchored to named builders and their artifacts, names the specific slop to reject, and enforces the three output gates (quote, named principle, concrete consequence — encoded in `workflow.js`, both in the scaffold prompt and the schemas). Add new principles to a lens's HOW THEY THINK section, never to FLAG — FLAG is the finding budget, and more categories just buy more nits. New lens = one file in `references/lenses/` + one table row.
