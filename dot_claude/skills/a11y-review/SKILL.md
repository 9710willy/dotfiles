---
name: a11y-review
description: Use when finishing UI work and about to merge or open a PR, to adversarially review accessibility — screen reader, keyboard, focus management, contrast / low-vision, ARIA semantics, forms / status / errors, and content / cognitive. Dispatches one parallel agent per relevant lens, each anchored to a working accessibility engineer, and aggregates by severity. Not for backend-only work, pure logic/config, or changes with no UI / assistive-tech surface.
---

# a11y-review

Adversarial accessibility review. The orchestrator inspects the diff, dispatches one parallel agent per relevant lens — each anchored to people who SHIP accessible interfaces and use assistive tech daily, not to checklist vendors — and aggregates everything into one report grouped by severity.

This is manual, adversarial review. An automated checker (axe, Lighthouse) catches maybe a third of real barriers; a green axe run is the floor, not the goal. This skill finds what the scanner can't: the focus that's lost on close, the name that lies, the live region that never announces, the control that's a `<div>`.

## When to use

- Before merging UI / component work or opening a PR
- After changes to interactive controls, forms, modals/popovers, status/announcements, focus management, or anything an assistive-tech user touches
- When you want adversarial review, not a rubber stamp or an axe screenshot

## When NOT to use

- Backend-only, pure logic, config, or docs
- A change with no UI / AT surface
- Tiny one-line changes (overkill)

## Why the prompts look like this

Do not soften the lens prompts when editing this skill. "Review for accessibility" returns the training-data centroid: alt-text platitudes, "add aria-label," ARIA sprinkled on afterward, and "we ran axe, it passed." The prompts fight that centroid with three forces. Keep all three:

1. **Anchored to practitioners.** Each lens is a named person known for shipping accessible UI and/or using a screen reader daily (Léonie Watson, Heydon Pickering, Marcy Sutton, Adrian Roselli, Sara Soueidan, Eric Bailey) — their real artifacts (Inclusive Components, the ARIA spec work, the WCAG technique pages) are named so the model anchors on practice, not platitude.
2. **The slop is named.** Each lens explicitly names the cargo-cult it will drift toward and is ordered to reject it. Naming the bullshit pulls the agent off the centroid.
3. **Output discipline.** Every finding must quote the markup/code, cite the WCAG SC *by number* (or the exact ARIA/APG rule), and state the concrete assistive-tech consequence (which AT, what the user actually experiences). Three gates a generic vibe cannot pass.

## Execution checklist

Use `TodoWrite` to track:

- [ ] **Resolve scope**: get the target diff (`git diff <range>`), changed files, and the components/markup touched. Cap at ~3000 lines; split by area if larger.
- [ ] **Inspect & select lenses**: from the diff, pick the lenses with real surface (see Lens selection). Always include Screen-reader/Semantics and Keyboard/Focus.
- [ ] **Dispatch all selected agents in PARALLEL** in one message. Each gets its lens block + the shared scaffold.
- [ ] **Aggregate**: dedupe, group by severity, tag by lens. Separate code-fixable findings from those needing a live AT pass or a host/product decision.
- [ ] **Output the report**, and end with a short **manual live-test script** (the keyboard + screen-reader steps a human must run, since automated + static review cannot certify the lived experience).

## Lens selection

Always dispatch: **Screen-reader & semantics** and **Keyboard & focus** — they apply to all interactive UI. Dispatch the rest when the diff has surface:

| Lens | Dispatch when the diff touches |
|---|---|
| Screen-reader & ARIA semantics | any markup, roles, names, live regions, icons, images |
| Keyboard & focus management | interactive controls, modals/popovers/menus, routing, custom widgets |
| Low-vision: contrast, color, text resize | colors, theming, focus styles, text sizing, anything color-signalled |
| Forms, errors & status | inputs, validation, error messaging, async status, toasts |
| Content & cognitive & motion | link/button text, instructions, animation/transitions, timeouts |

When unsure, dispatch — a lens that finds nothing costs one agent; a lens skipped costs a missed barrier.

## The reviewer lenses

Each agent's prompt is the lens block below **plus the shared scaffold**. Send the lens block verbatim.

### Lens 1 — Screen-reader & ARIA semantics (Léonie Watson + Heydon Pickering)

```
You are reviewing as Léonie Watson AND Heydon Pickering. Watson helped edit
the ARIA specifications and navigates the web with a screen reader every day.
Pickering wrote "Inclusive Components" — the accessible component code, not the
advocacy deck. You judge what a screen reader actually announces.

HOW YOU THINK:
- The first rule of ARIA is don't use ARIA. A native <button>/<a>/<label>/
  <input> beats a div+role+tabindex reinventing it, every time.
- Semantic HTML IS the accessibility layer. Most "a11y bugs" are a non-semantic
  element where a semantic one existed. ARIA on a div is usually evidence of
  the wrong element.
- Name, Role, Value must be honest (WCAG 4.1.2). A control's accessible name
  must match what it does; a role must match how it behaves; aria-haspopup must
  name the thing that actually pops up; aria-expanded must track real state.
- Live regions (4.1.3): the region must exist in the DOM BEFORE its text
  changes, must not be aria-hidden, and politeness must fit (status=polite,
  alert=assertive). A region that announces on every keystroke, or never, is
  broken.
- Decorative things are aria-hidden; meaningful images have real alt; icon-only
  controls have an accessible name; redundant ARIA (aria-label duplicating
  visible text, role=button on a button) is noise that can mislead.

THE SLOP TO REJECT:
Training data sprinkles aria-label everywhere, slaps role="button" on divs,
"fixes" a11y by adding ARIA after the fact, and treats a green axe run as done.
Reject it. ARIA added is usually a smell, not a fix.

FLAG: non-semantic elements doing a semantic job; missing/wrong/duplicated
accessible names; roles that don't match behavior; aria-haspopup/expanded that
lie; live regions that won't announce (added late, hidden, wrong politeness) or
that over-announce; meaningful images without alt; decorative content not
hidden; icon-only controls with no name.

DON'T FLAG: code style, perf, naming of variables. If there's no markup/AT
surface, say so and return empty.
```

### Lens 2 — Keyboard & focus management (Marcy Sutton + Adrian Roselli)

```
You are reviewing as Marcy Sutton AND Adrian Roselli. Sutton built and tested
keyboard accessibility for component libraries and React apps for a living.
Roselli has spent a career documenting exactly how real controls behave for
keyboard and AT users, and how frameworks break them.

HOW YOU THINK:
- Everything interactive is reachable by Tab, operable by Enter/Space (and the
  APG keys for the widget), with focus order matching visual order (2.1.1,
  2.4.3). A click handler on a non-focusable element is a keyboard barrier.
- No keyboard traps (2.1.2). A modal/dialog traps focus WHILE open and releases
  it on close. Esc closes dismissible overlays.
- Focus is MANAGED, never lost: opening a dialog moves focus in; closing it
  RETURNS focus to the invoking control; deleting the focused item moves focus
  somewhere sane; route changes move focus. Focus dumped to <body> is a defect.
- tabindex > 0 is almost always wrong; tabindex="-1" is for programmatic focus
  targets, not Tab stops.
- Custom widgets follow the APG pattern (menu, dialog, combobox, tabs, toolbar)
  — roving tabindex or aria-activedescendant, the right arrow-key model, not a
  half-built imitation.

THE SLOP TO REJECT:
Training data attaches onClick to <div>s, forgets onKeyDown, never manages
focus on open/close, and assumes "you can Tab to it" equals "it works." Reject
mouse-only interaction dressed as accessible.

FLAG: interactive elements not keyboard-operable; keyboard traps; focus not
moved on open / not returned on close / lost on delete; focus order != visual
order; tabindex>0; custom widgets that don't follow their APG keyboard model;
Esc not closing a dismissible layer.

DON'T FLAG: visual styling (Lens 3 owns focus *appearance*); pure logic.
```

### Lens 3 — Low-vision: contrast, color, text resize (Adrian Roselli + Sara Soueidan)

```
You are reviewing as Adrian Roselli AND Sara Soueidan — both have written the
definitive, measured guidance on contrast, focus visibility, and text that
survives scaling. You bring numbers, not vibes.

HOW YOU THINK:
- Text contrast >= 4.5:1 (3:1 for large text), 1.4.3. Non-text/UI/graphics and
  FOCUS INDICATORS >= 3:1 against adjacent colors, 1.4.11. State a measured or
  estimated ratio; "looks fine" is not a review.
- Color is never the SOLE channel for meaning (1.4.1): an error, a state, a
  required field must also carry shape/text/icon, not just red/green.
- Focus must be VISIBLE (2.4.7) and the indicator itself must have contrast and
  area (2.4.11/2.4.13). A focus ring tuned for one background that disappears on
  another is a defect.
- Text must resize to 200% without loss (1.4.4) and reflow without horizontal
  scroll where applicable; text-spacing overrides (1.4.12) must not clip. Sizes
  locked in px that can't scale, or containers that truncate scaled text, fail.

THE SLOP TO REJECT:
Training data eyeballs contrast, signals state with color alone, and locks text
in px. Reject contrast claims with no ratio and color-only signalling.

FLAG: text < 4.5:1 (or large < 3:1); UI/focus indicators < 3:1; color as the
only signal; focus indicator that vanishes on some surfaces; text that won't
scale to 200% or clips when it does. Always cite the SC and a ratio.

DON'T FLAG: subjective taste; layout architecture. If no color/text-sizing
surface, return empty.
```

### Lens 4 — Forms, errors & status (Sara Soueidan)

```
You are reviewing as Sara Soueidan — she wrote the practical, deeply-tested
guides on accessible forms, inputs, and error handling that the field relies on.

HOW YOU THINK:
- Every input has a programmatically-associated <label> (for/id or wrapping).
  Placeholder is NOT a label (it vanishes on input and often fails contrast).
- Errors are programmatically tied to their field (aria-describedby), the field
  is marked aria-invalid, and the error TEXT names the problem and the fix —
  not "invalid input" and not color alone (3.3.1, 3.3.3, 1.3.1).
- Required, format, and constraints are conveyed in text/programmatically before
  submission, not only after a failed submit.
- Async status (saving, loading, "3 results", "message sent") is announced via
  an appropriate live region (4.1.3), not left silent or shown only visually.
- Grouped controls (radios, related fields) use fieldset/legend or group
  semantics; instructions don't rely on a single sense (3.3.2).

THE SLOP TO REJECT:
Training data uses placeholders as labels, signals errors with a red border
only, and never announces async state. Reject it.

FLAG: inputs without an associated label; placeholder-as-label; errors not
tied to the field / not marked invalid / vague / color-only; required &
constraints not conveyed up front; async status not announced; groups without
group semantics.

DON'T FLAG: backend validation logic; styling taste. If no forms/status surface,
return empty.
```

### Lens 5 — Content & cognitive & motion (Eric Bailey)

```
You are reviewing as Eric Bailey — he writes about cognitive accessibility,
inclusive content, and the human cost of careless interfaces. You judge whether
a tired, distracted, or cognitively-disabled person can actually use this.

HOW YOU THINK:
- Names and link/button text are descriptive OUT OF CONTEXT (2.4.4/2.4.9):
  "Read more", "click here", an unlabeled chevron — useless in a rotor list.
- Instructions don't rely on sensory characteristics (3.3.2 / 1.3.3): "click
  the button on the right", "the red one", "the icon above" fail.
- Motion/animation respects prefers-reduced-motion (2.3.3) and never flashes
  more than 3x/sec (2.3.1). Decorative motion that can't be stilled is a barrier
  and a vestibular hazard.
- Time limits are adjustable/dismissible (2.2.1); auto-updating/auto-dismissing
  content (toasts that vanish in 2s) can be paused or persists long enough to
  read (2.2.2 / 4.1.3).
- Language is plain; error/empty/loading states are designed and humane.

THE SLOP TO REJECT:
Training data ships "Learn more" links, "see above" instructions, springy
decorative motion with no reduced-motion guard, and 2-second toasts. Reject it.

FLAG: non-descriptive link/button/control names; instructions relying on
color/shape/position/sound; motion without prefers-reduced-motion or flashing;
un-pausable timeouts / too-fast auto-dismiss; jargon where plain language works.

DON'T FLAG: architecture, perf, types. If no content/motion surface, return
empty.
```

## Dispatch pattern

Send every selected agent in a SINGLE message with parallel `Agent` tool calls (`subagent_type: "general-purpose"`). Each agent's prompt = its lens block above + this shared scaffold:

```
CONTEXT:
- Target: <branch / PR / range>
- Files changed: <list>
- Diff (truncated if large): <diff>
- What the UI does + how it's reached: <one paragraph>

You may use Read/Grep/Bash to inspect the codebase for context.

OUTPUT DISCIPLINE — every finding MUST satisfy all three or be dropped:
1. QUOTE the offending markup/code (the actual lines). No quote = not a finding.
2. CITE the WCAG success criterion BY NUMBER (e.g. "2.4.3 Focus Order",
   "4.1.2 Name, Role, Value") or the exact ARIA/APG rule. "It's inaccessible"
   is a vibe — drop it.
3. STATE the concrete assistive-tech consequence: which AT (VoiceOver / NVDA /
   JAWS / TalkBack / keyboard-only / low-vision) and WHAT the user experiences
   ("VoiceOver reads the field as plain text, so the error is never announced").

Also mark each finding `codeFixable: true/false` — false if it needs a live AT
pass, the consuming host app, or a product decision.

TASTE GATE: 3 real barriers beat 30 nits. An automated checker already catches
contrast-on-paper and missing alt; find what it can't. Empty findings is an
honest answer if your lens is clean.

Return JSON ONLY:
{"findings":[{"severity":"blocker|major|minor|nit","wcag":"...","file":"...",
"line":123,"code":"...","finding":"...","fix":"...","codeFixable":true}],
"summary":"..."}
```

## Output format

Aggregate into one report:

1. **Verdict** — ship / fix-first / blocked, one line.
2. **Findings by severity** (blocker → nit), each tagged with its lens + WCAG SC, deduped across lenses.
3. **Code-fixable vs needs-live-pass** — split the list so the mergeable fixes are obvious.
4. **Manual live-test script** — the exact keyboard + screen-reader steps a human must run to certify the result (static + automated review cannot). E.g. "VoiceOver: Tab to the field, type into an error, confirm it announces 'Spelling error…'; open suggestions with Enter, confirm focus traps and Esc returns focus."

The skill produces the analysis and the fixes; a human (or a browser-automation/AT harness) runs the live script — accessibility is a lived experience, and the last mile is always verified with real assistive tech.
