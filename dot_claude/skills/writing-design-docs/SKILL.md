---
name: writing-design-docs
description: Use when writing or restructuring an engineering design doc, TDR, RFC, or technical proposal (Confluence or markdown) — before drafting any prose, or when a draft reads wordy or novel-like, reviewers can't scan it, or cross-references and citations don't link anywhere
---

# Writing Design Docs

## Overview

A design doc is a decision record for reviewers, not an essay. Optimize for one flow: a reviewer jumps to the sections they must approve, finds the decision, the evidence, and the trade-off, and gets out. Every sentence that doesn't carry a decision-relevant fact slows that down.

## Document shape (in order)

1. **Status line**: status, author, created/revised dates. One `<p>`.
2. **TL;DR**: one or two short paragraphs (4-7 sentences total). Problem magnitude (measured number), the move, integration cost, the open risk and which gate measures it, cost envelope, where the decision record and asks live.
3. **Approvals table** with a per-approver "start here" column linking to their sections.
4. **Glossary**: one line per term a reviewer might not know.
5. **Numbered sections** with stable IDs: sections are §1..§N, decisions are D1..Dn. Every cross-reference is a clickable anchor link, never bare text.
6. **Decision blocks** (one per h3): title states the decision itself. Then: `Alternatives considered:` line (italic), one short evidence paragraph, explicit `Trade-off:` line (bold label). Never bury the trade-off mid-paragraph.
7. **Tables for enumerable facts** (current state, failure modes, phases, risks, costs). Bullets for everything list-shaped. Prose only where an argument genuinely flows; one idea per paragraph.
8. **References that resolve**: every named internal doc is a link. If it exists only locally, publish/attach it (e.g. as a child page), then link it. Tickets link to the tracker. Never invent an href.

## Tone (staff-engineer register)

- Short declarative sentences, active voice. Front-load each paragraph's conclusion.
- Terse beats fluent. Cut connective tissue ("moreover", "in order to", "note that", "which means that"). If a sentence survives without a clause, the clause goes.
- Fragments welcome when meaning survives: "Config-only. No client changes." Grammatical completeness is not a goal; scannability is (Will, 2026-07-23).
- Numbers over adjectives: "needs 47.5 engines > 25", not "significant pool pressure".
- Hedge only with data: "~0.2s (estimated, not yet measured)", never "should probably be fine".
- `=` and `+` are fine in terse fragments ("Buying = our architecture minus our governance"); avoid `incl.` and `w/`.
- State each fact once; cross-ref it everywhere else.
- Evidence rides in parentheticals ("(verified on the v6.8 tag)"), not narrative sentences ("It is worth noting that we verified...").

## Confluence mechanics (storage format)

Anchors + links make §/D refs clickable:

```html
<!-- target: inside the heading -->
<h2><ac:structured-macro ac:name="anchor" ac:schema-version="1"><ac:parameter ac:name="">s8-2</ac:parameter></ac:structured-macro>8.2 Cost analysis</h2>
<!-- reference -->
<ac:link ac:anchor="s8-2"><ac:plain-text-link-body><![CDATA[§8.2]]></ac:plain-text-link-body></ac:link>
<!-- other Confluence pages -->
<ac:link><ri:page ri:content-title="Exact Page Title" /></ac:link>
```

Do the linkification mechanically (script over the storage HTML), not by hand: anchor headings last, skip headings when linkifying refs, never linkify inside CDATA.

## Sanity check (run before every publish)

Run the paragraph linter over the storage HTML before `confl update`:

```bash
python3 scripts/paragraph-lint.py body.html   # exits 1 on any FAIL
```

It flags every `<p>`/`<li>` over 60 visible words (WARN) or 90 (FAIL), plus semicolon pileups. Fix FAILs by restructuring (claim sentence stays a `<p>`, enumerable payload becomes bullets), never by deleting facts. Confluence renders long paragraphs as dense full-width walls; what looks fine in a draft reads as a slab on the page (learned 2026-07-23, TDR D5 hit 247 words in one `<p>`).

## Common mistakes

| Mistake | Fix |
|---|---|
| Whole section as one `<p>` with bold inline labels | One block element per idea: list, table, or split paragraphs |
| Paragraph over ~60 visible words (renders as a wall) | Split into claim + bullets; `scripts/paragraph-lint.py` catches these mechanically |
| Trade-off buried mid-paragraph | Dedicated bold `Trade-off:` line per decision |
| References name docs that live nowhere, or fabricated hrefs | Publish/attach the doc, then link; never cite an unreachable doc |
| Evidence written as narrative sentences | Parenthetical citation on the claim |
| Restating a fact in three sections | State once, anchor-link from the others |
| TL;DR missing or restating the title | 4-7 sentences with the numbers and the ask |
