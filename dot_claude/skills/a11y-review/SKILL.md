---
name: a11y-review
description: Use when finishing UI work and about to merge or open a PR, to adversarially review accessibility — screen reader, keyboard, focus management, contrast / low-vision, ARIA semantics, forms / status / errors, and content / cognitive. Dispatches one parallel agent per relevant lens, each anchored to a working accessibility engineer, and aggregates by severity. Not for backend-only work, pure logic/config, or changes with no UI / assistive-tech surface.
---

# a11y-review

Adversarial accessibility review. Inspect the diff, dispatch one parallel agent per relevant lens, aggregate into one report grouped by severity.

An automated checker (axe, Lighthouse) catches maybe a third of real barriers — the floor, not the goal. This finds what scanners can't: focus lost on close, a name that lies, a live region that never announces, a control that's a `<div>`.

## Input

`$ARGUMENTS` — optional. A PR number, branch, or diff range. Empty → current branch vs the main branch.

## Steps

1. **Resolve scope.** Get `git diff --stat <range>`, the changed files, and which components/markup are touched. Cap at ~3000 lines; split by area and run once per slice if larger.
2. **Select lenses** from the table. The first two always dispatch. When unsure, dispatch — a lens that finds nothing costs one agent; a skipped lens costs a missed barrier.
3. **Dispatch all agents in one message** as parallel `Agent` calls (`subagent_type: "general-purpose"`), each with the scaffold below and its own lens path.
4. **Aggregate** and print the report, ending with the manual live-test script.

## Lenses

Files live in `~/.claude/skills/a11y-review/references/lenses/`. Pass the absolute path; each agent reads its own lens.

| Lens file | Dispatch when the diff touches |
|---|---|
| `sr-semantics.md` | Always — any markup, roles, names, live regions, icons, images |
| `keyboard-focus.md` | Always — interactive controls, overlays, routing, custom widgets |
| `low-vision.md` | Colors, theming, focus styles, text sizing, anything color-signalled |
| `forms-status.md` | Inputs, validation, error messaging, async status, toasts |
| `content-cognitive.md` | Link/button text, instructions, animation/transitions, timeouts |

## Agent prompt scaffold

```
FIRST: Read <absolute lens path>. That file IS your reviewing lens — adopt it
fully, including what it says not to flag. Do not review from generic best
practices.

CONTEXT:
- Repo root: <path>
- Range: <range>
- Files changed: <list>
- What the UI does + how it's reached: <one paragraph>

Get the diff yourself: `git -C <root> diff <range> -- <files>`. Read whole
files and Grep for context when a finding depends on markup outside the diff.

Every finding must pass all three gates or be dropped:
1. QUOTE the offending markup/code. No quote = not a finding.
2. CITE the WCAG success criterion BY NUMBER ("2.4.3 Focus Order", "4.1.2
   Name, Role, Value") or the exact ARIA/APG rule. "It's inaccessible" is a
   vibe — drop it.
3. STATE the concrete assistive-tech consequence: which AT (VoiceOver / NVDA /
   JAWS / TalkBack / keyboard-only / low-vision) and what the user experiences
   ("VoiceOver reads the field as plain text, so the error is never announced").

Mark each finding codeFixable — false if it needs a live AT pass, the
consuming host app, or a product decision.

Signal over volume: 3 real barriers beat 30 nits. A scanner already catches
contrast-on-paper and missing alt; find what it can't. An empty findings
array is an honest answer if your lens is clean.

Return JSON only:
{"findings":[{"severity":"blocker|major|minor|nit","wcag":"...","file":"...",
"line":123,"code":"...","finding":"...","fix":"...","codeFixable":true}],
"summary":"..."}
```

## Report

1. **Verdict** — ship / fix-first / blocked, one line.
2. **Findings by severity** (blocker → nit), each tagged with lens + WCAG SC, deduped across lenses.
3. **Code-fixable vs needs-live-pass** — split so the mergeable fixes are obvious.
4. **Manual live-test script** — the exact keyboard + screen-reader steps a human must run to certify the result (e.g. "VoiceOver: Tab to the field, type an error, confirm it announces; open suggestions with Enter, confirm focus traps and Esc returns focus"). Static review cannot certify the lived experience; the last mile is real assistive tech.

## Editing this skill

The lens prompts fight the training-data centroid ("review for accessibility" returns alt-text platitudes and sprinkled aria-labels). Keep their three forces: each lens is anchored to named practitioners and their artifacts, names the specific slop to reject, and enforces the three gates (quote, WCAG number, AT consequence). Add new principles to a lens's HOW YOU THINK section, not FLAG — FLAG is the finding budget. New lens = one file in `references/lenses/` + one table row.
