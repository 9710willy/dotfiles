---
name: atlassian-curl
description: Use when interacting with Jira or Confluence — viewing issues, JQL search, creating/updating/transitioning tickets, adding comments, reading/creating Confluence pages, CQL search. Use the `jira` and `confl` wrapper scripts, not raw curl or Atlassian MCP.
---

Use the `~/bin/jira` and `~/bin/confl` wrapper scripts (on PATH). They read auth and site URLs from env vars exported in the shell profile (`ATLASSIAN_EMAIL`, `ATLASSIAN_TOKEN`, `ATLASSIAN_SITE`), trim responses to compact text, and convert ADF↔plain text. Run `jira` or `confl` with no args for usage.

## Jira

```bash
jira get KEY [extra,fields]        # issue summary/status/assignee + plain-text description
jira search 'JQL' [max] [fields]   # tab-separated key/status/assignee/summary; prints nextPageToken if more
jira count 'JQL'                   # approximate count
jira comments KEY [limit]          # newest first, plain text
jira comment KEY 'text'            # blank line in text = new paragraph
jira create PROJ Type 'summary' ['description']   # prints new key
jira update KEY '{"summary":"...","customfield_10023":5}'   # raw fields JSON
jira transitions KEY               # id / name list
jira transition KEY ID
jira user 'name or email'          # find accountId (JQL uses accountId, never names)
jira raw METHOD /path [curl args]  # escape hatch — full JSON, v3-relative path
```

If a transition fails with "field should be updated": `jira update` the field first, then transition (the transition body only accepts fields present on the transition screen).

## Confluence

```bash
confl get PAGEID                   # meta + body as readable text
confl body PAGEID                  # raw storage-format HTML (use before editing)
confl search 'CQL' [limit]         # id / type / title
confl create SPACEID 'title' [PARENTID] < body.html
confl update PAGEID 'title' < body.html   # auto-increments version
confl children PAGEID
confl raw METHOD /path-or-URL [curl args]
```

`create`/`update` take storage-format HTML on stdin (`<p>`, `<h2>`, `<ul>`, `<table>`, `<ac:structured-macro>` etc.). `update` replaces the whole body — fetch with `confl body` first when making partial edits.

## Site specifics

Field IDs and workflow rules are site-specific. Read `~/.claude/skills/atlassian-curl/SITE.md` for this machine's values; `jira raw GET /field` lists field IDs on a new site.

## Gotchas

- **Token efficiency:** prefer the subcommands; only use `raw` when a field/endpoint isn't covered, and pipe `raw` through a `jq` filter to keep output small.
- JQL search uses `/search/jql` with `nextPageToken` cursor pagination (old `/search` returns 410; no `total` field — use `jira count`). JQL must be **bounded** (a bare `ORDER BY` is rejected).
- Jira search is **eventually consistent** — a just-created/updated issue may not appear in search immediately; `jira get` it directly for read-after-write.
- In JQL and payloads reference people by `accountId` (`jira user` to look up), never username/email.
- Confluence CQL search is v1-only (`/wiki/rest/api/search`); the v2 API has no search endpoint. Wrapper handles this. CQL user fields (`user`, `user.accountid`, …) are unsupported there and silently return empty — use `creator`/`contributor` with an accountId.
- Jira v3 bodies (description/comments) are ADF. Wrappers convert to/from plain text; for rich formatting (code blocks, links, mentions) build ADF JSON and use `jira raw`.
- Never use curl `-u` (mangles token chars) or `-v` (dumps the auth header) — the wrappers avoid both.
- API tokens expire; rotate at https://id.atlassian.com/manage-profile/security/api-tokens. Requests are rate-limited (429 + `Retry-After`) — back off, don't hammer.
