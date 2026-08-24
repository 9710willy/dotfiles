export const meta = {
  name: 'dev-review',
  description: 'Adversarial multi-lens code review with schema-validated findings',
  phases: [
    { title: 'Review', detail: 'one agent per selected lens' },
    { title: 'Synthesize', detail: 'dedupe, resolve evidence conflicts' },
  ],
}

const FINDING = {
  type: 'object',
  required: ['severity', 'file', 'line', 'code', 'principle', 'finding', 'suggestion', 'verified', 'confidence', 'falsePositiveCase'],
  properties: {
    severity: { type: 'string', enum: ['blocker', 'major', 'minor', 'nit'] },
    file: { type: 'string' },
    line: { type: 'integer' },
    code: { type: 'string', minLength: 1 },
    principle: { type: 'string', minLength: 1 },
    finding: { type: 'string', minLength: 1 },
    suggestion: { type: 'string' },
    verified: { type: 'string', minLength: 1 },
    confidence: { type: 'integer', minimum: 0, maximum: 100 },
    falsePositiveCase: { type: 'string', minLength: 1 },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  required: ['findings', 'summary'],
  properties: {
    findings: { type: 'array', items: FINDING },
    summary: { type: 'string' },
  },
}

const SYNTH_SCHEMA = {
  type: 'object',
  required: ['findings', 'resolved', 'disputed'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'file', 'line', 'lenses', 'code', 'principle', 'finding', 'suggestion', 'unverified', 'confidence'],
        properties: {
          severity: { type: 'string', enum: ['blocker', 'major', 'minor', 'nit'] },
          file: { type: 'string' },
          line: { type: 'integer' },
          lenses: { type: 'array', items: { type: 'string' } },
          code: { type: 'string' },
          principle: { type: 'string' },
          finding: { type: 'string' },
          suggestion: { type: 'string' },
          unverified: { type: 'boolean' },
          whatToCheck: { type: 'string' },
          confidence: { type: 'integer', minimum: 0, maximum: 100 },
          falsePositiveCase: { type: 'string' },
        },
      },
    },
    resolved: { type: 'array', items: { type: 'string' } },
    disputed: { type: 'array', items: { type: 'string' } },
  },
}

const { repoRoot, range, techInventory, commits, lenses } = args

phase('Review')
const reviews = (await parallel(lenses.map(l => () => agent(
`FIRST: Read ${l.path}. That file IS your reviewing lens — adopt it fully, including what it says not to flag. Do not review from generic best practices.

CONTEXT:
- Repo root: ${repoRoot}
- Range: ${range}
- Slice you are reviewing: ${l.slice}
- Tech inventory: ${techInventory}
- Files in your slice: ${l.files.join(', ')}
- Commit messages: ${commits}

Get the diff yourself (first tool call after reading your lens):
git -C ${repoRoot} diff ${range} -- <the files in your slice>
Then Read whole files, Grep for callers, and open a dependency's source when a finding depends on a contract outside the diff. Confirm or kill each suspicion by reading the code before you write it up.

Every finding must pass all three gates or be dropped:
1. QUOTE the offending lines in "code". No quote = not a finding.
2. CITE the violated principle by name in "principle" ("APoSD: shallow module", "DDIA Ch.7: write skew", "parse, don't validate"). Can't name it = a vibe = drop it.
3. STATE the concrete consequence in "finding" ("two concurrent requests lose updates"), not a category ("performance concern").

"verified" = what you checked and where (file:line or package path), or "UNVERIFIED: <what you could not see>".

Then two more fields on every finding:

4. "falsePositiveCase" — argue the OPPOSITE. State the strongest specific reason this finding might be wrong: the guard you may have missed, the caller that never passes that input, the invariant held elsewhere. Write "none: <the fact that rules it out>" only when you actually checked and can name the fact. This is not a disclaimer — a finding you cannot argue against is one you have not tested.
5. "confidence" — an integer 0-100: how sure you are this is a real defect, AFTER writing falsePositiveCase. Use the whole range. Reserve 90+ for defects you traced end to end; 70-89 for a real defect whose trigger you could not fully confirm; 40-69 for a genuine maybe; below 40 you should probably drop it. Do not pile up at 95 and 100 — a scale you only use two values of is a two-point scale, and it forces the reader to eyeball everything.

Signal over volume: three real blockers beat thirty nits. Cut any nit the engineer your lens is named for would not bother typing. An empty findings array is an honest answer — do not invent findings to look thorough.`,
  { label: 'review:' + l.name, phase: 'Review', schema: REVIEW_SCHEMA }
).then(r => r && { lens: l.name, summary: r.summary, findings: r.findings.map(f => ({ ...f, lens: l.name })) })
))).filter(Boolean)

const all = reviews.flatMap(r => r.findings)

phase('Synthesize')
let synth = {
  findings: all.map(f => ({
    severity: f.severity, file: f.file, line: f.line, lenses: [f.lens],
    code: f.code, principle: f.principle, finding: f.finding, suggestion: f.suggestion,
    unverified: f.verified.indexOf('UNVERIFIED') === 0, whatToCheck: f.verified,
    confidence: f.confidence, falsePositiveCase: f.falsePositiveCase,
  })),
  resolved: [], disputed: [],
}
if (reviews.length > 1 && all.length > 1) {
  synth = (await agent(
`You are merging code-review findings from ${reviews.length} independent reviewer lenses into one set. Apply these rules exactly:

1. Verified beats unverified, always. Each finding's "verified" field names what its reviewer actually read (file:line / package path) or starts with UNVERIFIED. If one lens verified a fact that kills a finding another lens only inferred, drop the loser and add one line to "resolved": "[Lens A] claimed <finding>; [Lens B] verified <fact> at <where>. Dropped."
2. If two findings are both verified and still disagree (a genuine trade-off), keep neither in "findings"; add one line to "disputed": "<file>:<line> — [Lens A] <position> · [Lens B] <position> — Settled by: <the specific check that decides it>". Do not pick a winner.
3. Merge duplicates (same defect on the same or adjacent lines): one entry, all contributing lenses in "lenses", the HIGHEST severity any of them assigned.
4. Carry "confidence" through unchanged. On a merge (rule 3) take the HIGHEST confidence any contributing lens assigned, alongside the highest severity. Lower a finding's confidence only when you read code that partly undercuts it, and say so in one clause appended to its "falsePositiveCase".
5. Everything else passes through unchanged — same severity, code quote, principle, finding, suggestion. Set "unverified" true and copy the reviewer's note into "whatToCheck" when its verified field starts with UNVERIFIED. Do not add findings, soften severities, or pad.

If settling rule 1 or 2 needs a fact, read the code yourself: repo root ${repoRoot}, range ${range}.

The findings:
${JSON.stringify(all, null, 1)}`,
    { label: 'synthesize', phase: 'Synthesize', schema: SYNTH_SCHEMA }
  )) || synth
}

const rank = { blocker: 0, major: 1, minor: 2, nit: 3 }
synth.findings.sort((a, b) => (rank[a.severity] - rank[b.severity])
  || ((b.confidence ?? 0) - (a.confidence ?? 0))
  || a.file.localeCompare(b.file) || (a.line - b.line))
const counts = { blocker: 0, major: 0, minor: 0, nit: 0 }
synth.findings.forEach(f => { counts[f.severity]++ })

return {
  findings: synth.findings,
  resolved: synth.resolved,
  disputed: synth.disputed,
  summaries: reviews.map(r => ({ lens: r.lens, summary: r.summary })),
  counts,
  lensesRun: reviews.map(r => r.lens),
  lensesSelected: lenses.map(l => l.name),
}
