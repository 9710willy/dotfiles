---
name: atlassian-curl
description: Use when interacting with Jira or Confluence, such as viewing issues, JQL search, updates, transitions, comments, pages, and CQL search. Use the `jira` and `confl` wrappers.
---

Use the `~/bin/jira` and `~/bin/confl` wrapper scripts. They read auth and site URLs from `ATLASSIAN_EMAIL`, `ATLASSIAN_TOKEN`, and `ATLASSIAN_SITE`. They trim responses and convert between ADF and plain text. Run `jira` or `confl` with no arguments for usage.

Long output is capped at 200 lines. `jira get`, `jira comments`, and `confl get` show a full heading outline before the capped body. Set `ATLASSIAN_MAX_LINES=N` to change the cap, or set it to `0` to remove the cap. `confl body` is never capped because a partial body would corrupt an update.

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
jira user 'name or email'          # find accountId
jira raw METHOD /path [curl args]  # full JSON, v3-relative path
```

If a transition says a field must be updated, run `jira update` first. A transition body accepts only fields on the transition screen.

## Confluence

```bash
confl get PAGEID                   # meta + body as readable text
confl body PAGEID                  # raw storage-format HTML
confl search 'CQL' [limit]         # id / type / title
confl create SPACEID 'title' [PARENTID] < body.html
confl update PAGEID 'title' < body.html   # auto-increments version
confl children PAGEID
confl raw METHOD /path-or-URL [curl args]
```

`create` and `update` read storage-format HTML from standard input. `update` replaces the whole body. Run `confl body` before a partial edit.

## Site specifics

Read `~/.claude/skills/atlassian-curl/SITE.md` for this machine's field IDs and workflow rules. Run `jira raw GET /field` to list field IDs on a new site.

## Gotchas

- Prefer the subcommands. Use `raw` only when they do not cover a field or endpoint. Filter `raw` output with `jq` when possible.
- JQL search uses `/search/jql` with `nextPageToken`. The old `/search` endpoint returns 410. A JQL query must be bounded.
- Jira search is eventually consistent. After a write, use `jira get` for an immediate read.
- Use an `accountId` for people in JQL and payloads. Run `jira user` to find one.
- Confluence CQL search uses `/wiki/rest/api/search`. The v2 API has no search endpoint.
- Jira v3 descriptions and comments use ADF. The wrappers convert plain text. Use `jira raw` for rich formatting.
- Never use `curl -u` or `curl -v`. The wrappers protect the token and authorization header.
- Requests can return 429 with `Retry-After`. Wait for that interval before you retry.
