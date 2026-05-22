---
name: atlassian-curl
description: Use when interacting with Jira or Confluence — viewing issues, JQL search, creating/updating/transitioning tickets, adding comments, reading/creating Confluence pages, CQL search. Replaces Atlassian MCP with direct curl calls.
---

## Setup

```bash
# Required env vars (set in shell profile or export before use)
export ATLASSIAN_EMAIL="your-email@five9.com"
export ATLASSIAN_TOKEN="your-api-token"  # https://id.atlassian.com/manage-profile/security/api-tokens
export JIRA_BASE="https://five9inc.atlassian.net/rest/api/3"
export CONFLUENCE_BASE="https://five9inc.atlassian.net/wiki/api/v2"
export CONFLUENCE_V1_BASE="https://five9inc.atlassian.net/wiki/rest/api"  # Required for CQL search (v2 has no search endpoint)
```

**IMPORTANT — Auto-compute auth before every curl session:**

`ATLASSIAN_AUTH` must be computed from email+token. It does NOT persist across shell sessions (subshells, subagents, new terminals). **Always run this preamble before any curl calls:**

```bash
export ATLASSIAN_AUTH=$(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_TOKEN" | base64)
export CONFLUENCE_V1_BASE="${CONFLUENCE_V1_BASE:-https://five9inc.atlassian.net/wiki/rest/api}"
export JIRA_BASE="${JIRA_BASE:-https://five9inc.atlassian.net/rest/api/3}"
```

Auth header for all requests: `-H "Authorization: Basic $ATLASSIAN_AUTH"`

**IMPORTANT:** Do NOT use curl's `-u` flag — API tokens contain special characters that get mangled by `-u`. Always use the pre-encoded `$ATLASSIAN_AUTH` header.

## Jira

**Get issue:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" "$JIRA_BASE/issue/PROJ-123"
```

**Search (JQL)** — use `/rest/api/3/search/jql`, NOT the deprecated `/search`:
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -G "$JIRA_BASE/search/jql" \
  --data-urlencode "jql=project = PROJ AND status = 'In Progress'" \
  --data-urlencode "fields=summary,status,assignee,priority" \
  --data-urlencode "maxResults=50"
```
Paginate with `nextPageToken` from response (NOT `startAt`).

**Create issue:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE/issue" \
  -d '{"fields":{"project":{"key":"PROJ"},"issuetype":{"name":"Task"},"summary":"Title here","description":{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"Description here"}]}]}}}'
```

**Update fields:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X PUT "$JIRA_BASE/issue/PROJ-123" \
  -d '{"fields":{"summary":"New title","customfield_10023":5}}'
```

**Transition** (2-step — get available transitions, then apply):
```bash
# Step 1: Get transitions
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" "$JIRA_BASE/issue/PROJ-123/transitions"
# Step 2: Apply (use id from step 1)
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE/issue/PROJ-123/transitions" \
  -d '{"transition":{"id":"31"}}'
```

**Transition with required fields** — if transition fails with "field should be updated", set the field first with PUT then transition:
```bash
# Step 1: Set required field
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X PUT "$JIRA_BASE/issue/PROJ-123" \
  -d '{"fields":{"customfield_10065":{"value":"Core","child":{"value":"ADP,Sup+"}}}}'
# Step 2: Transition
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE/issue/PROJ-123/transitions" \
  -d '{"transition":{"id":"41"}}'
```
Note: v3 rejects cascading select fields in the transition body ("cannot be set, not on appropriate screen"). The 2-step approach (PUT then transition) works reliably.

**Add comment** (v3 requires ADF):
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X POST "$JIRA_BASE/issue/PROJ-123/comment" \
  -d '{"body":{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"Comment text here"}]}]}}'
```

## Confluence

**Get page:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  "$CONFLUENCE_BASE/pages/123456789?body-format=storage"
```

**Search (CQL)** — uses v1 API (`$CONFLUENCE_V1_BASE`), NOT v2 (v2 has no search endpoint):
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -G "$CONFLUENCE_V1_BASE/search" \
  --data-urlencode "cql=title ~ \"meeting\" AND type = page" \
  --data-urlencode "limit=25"
```
Paginate by following `_links.next` URL from response (cursor-based), NOT `startAt`.

**Create page:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X POST "$CONFLUENCE_BASE/pages" \
  -d '{"spaceId":"SPACE_ID","title":"Page Title","parentId":"PARENT_ID","body":{"representation":"storage","value":"<p>Content here</p>"}}'
```

**Update page** (requires current version number + 1):
```bash
# Get current version first
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" "$CONFLUENCE_BASE/pages/123456789" | jq '.version.number'
# Update with incremented version
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" \
  -H "Content-Type: application/json" \
  -X PUT "$CONFLUENCE_BASE/pages/123456789" \
  -d '{"id":"123456789","status":"current","title":"Page Title","body":{"representation":"storage","value":"<p>Updated</p>"},"version":{"number":2,"message":"Updated via API"}}'
```

**Get child pages:**
```bash
curl -s -H "Authorization: Basic $ATLASSIAN_AUTH" "$CONFLUENCE_BASE/pages/123456789/children"
```

## Five9 Specifics

| Item | Value |
|------|-------|
| Cloud ID | `d476c8e7-4d06-4349-bce7-6688a55911ff` |
| Story Points field | `customfield_10023` |
| Story Point Estimate (different!) | `customfield_10016` |
| Color/label field (NOT points) | `customfield_10028` |
| Delivery Area/Team (required for Done) | `customfield_10065` |

## Gotchas

| Issue | Detail |
|-------|--------|
| v3 = ADF only | Descriptions and comments must use ADF (Atlassian Document Format), not plain text or markdown |
| Search endpoint removed | Use `/search/jql` not `/search` — the old one is fully removed, not just deprecated |
| Jira pagination | Use `nextPageToken` from response, not `startAt`/`startIndex`. No `total` field — use `POST /search/approximate-count` if needed |
| Confluence pagination | Cursor-based — follow `_links.next` URL from response, NOT `startAt` |
| URL encoding | Always `--data-urlencode` for JQL/CQL queries — spaces, quotes, operators break without it |
| ADF template | `{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"..."}]}]}` |
| Multi-paragraph ADF | Add multiple objects to the outer `content` array, each with `type: "paragraph"` |
| Transition required fields | If transition fails with "field should be updated", include `"fields":{...}` in the transition POST body. Fall back to v2 endpoint if v3 rejects it |
| Token expiry | API tokens have mandatory expiry. Tokens created before Dec 2024 are expiring NOW (March–May 2026). Check yours at https://id.atlassian.com/manage-profile/security/api-tokens and rotate immediately if needed |
| Rate limiting | API token requests are rate-limited since Nov 2025. Confluence rate limits enforce March 2026 |
| Confluence search is v1 only | CQL search uses `$CONFLUENCE_V1_BASE/search` (v1 API), NOT `$CONFLUENCE_BASE`. The v2 Confluence API has no search endpoint — it will 404 |
| Never use `-u` flag | curl's `-u` flag mangles special characters in API tokens. Always use `-H "Authorization: Basic $ATLASSIAN_AUTH"` with pre-encoded Base64 |
| Never log tokens | Use `-s` (silent) flag on all curl calls. Never use `-v` (verbose) — it dumps the Authorization header |
