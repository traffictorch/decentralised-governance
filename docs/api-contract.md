# API Contract

The governance engine exposes a small, well-defined HTTP API. The **Cloudflare Worker** in `engine/cloudflare/` is one implementation of this contract. Any backend that speaks the same shape — Node+Postgres, Supabase, Lambda+DynamoDB, Rails — will work with the same frontend.

This document defines that contract. It does not describe Cloudflare-specific implementation details.

---

## Conventions

**Base URL.** Whatever you deploy. Reference impl: `https://<name>.<subdomain>.workers.dev`.

**Content type.** All requests and responses are `application/json` unless stated. POST bodies must set `Content-Type: application/json`.

**Authentication.** Bearer JWT in the `Authorization` header:

    Authorization: Bearer <jwt>

The JWT is issued by *your* auth system (the engine doesn't issue tokens). It must contain an `id` claim — the user's stable identifier. The engine verifies the signature with the shared `JWT_SECRET` (HMAC-SHA256) and checks `exp` if present.

**CORS.** Reference impl uses `Access-Control-Allow-Origin: *` for simplicity. **In production, restrict this** to your frontend origin.

**Timestamps.** All timestamps in requests and responses are Unix seconds (integer). Never ISO strings.

**IDs.** Proposal IDs are opaque strings (e.g. `rt0001`, `rtmvbvxf4g`). Slugs are the URL-safe form. Most endpoints accept **either** ID or slug.

**Error shape.** Every error response is `{ "error": "Human-readable message" }` with an appropriate HTTP status. No nested error objects.

---

## Entity eligibility

An **entity** is a registered user who can vote. Eligibility is checked when a user first calls `/me`, and cached in `rt_entities`.

Eligibility rules (as of v1.0):

| Rule | Value | Source |
|---|---|---|
| Account age | >= 7 days | `users.created_at` |
| Prior activity | Any past action | *reserved; v1 uses account age + verification only* |
| Profile verified OR public | Either one | `users.verified_at IS NOT NULL OR users.profile_public = 1` |
| Human-operated | (assertion) | Trust |

**Eligibility snapshot.** When a vote opens, the count of currently-eligible entities is frozen on the proposal row (`eligible_count`). Entities who register after that moment **cannot** vote on that proposal. This prevents last-minute brigading.

---

## The proposal state machine

    draft --- open-vote ---> vote --- close-vote ---> passed / rejected / (no_quorum -> rejected)
    draft --- withdraw ----> withdrawn

**Only** these transitions are valid. Attempting any other transition returns 400.

- `draft` -> comment period ongoing. No voting yet.
- `vote` -> open. Votes can be cast/changed. Objections can pause it.
- `passed` / `rejected` -> closed. Reconsider window opens for 30 days.
- `withdrawn` -> author cancelled before vote opened. Permanent.

---

## Endpoints

### GET /api/rt/me

Check authentication status and eligibility. **Idempotent.** On first call, inserts the user into `rt_entities`.

**Auth:** optional. If absent -> `{ authenticated: false }` (200 OK).

**Response (authenticated):**

    {
      "authenticated": true,
      "entity_id": "53",
      "eligible": true,
      "eligible_since": 1771838045,
      "days_until_eligible": 0,
      "reason": null
    }

`reason` values: `login_required`, `invalid_token`, `user_not_found`, `account_too_new`, `profile_incomplete`, or `null` if eligible.

---

### GET /api/rt/proposals

List all proposals. Ordered by `created_at DESC`. Paginated via `LIMIT 50`.

**Auth:** optional (public list).

**Response:**

    {
      "proposals": [
        {
          "id": "rt0001",
          "slug": "ratify-constitution",
          "title": "Ratify the Constitution",
          "body_md": "...",
          "kind": "meta",
          "category": "meta",
          "phase": "draft",
          "author_entity_id": "system",
          "created_at": 1792203835,
          "vote_starts_at": null,
          "vote_ends_at": null,
          "quorum_pct": 0.20,
          "threshold_pct": 0.66,
          "block_pct": 0.25,
          "eligible_count": null,
          "tally_yes": 0,
          "tally_no": 0,
          "tally_abstain": 0,
          "resolution_id": null
        }
      ]
    }

**Cache-Control:** `public, max-age=60` in the reference impl.

---

### GET /api/rt/proposals/:slug_or_id

Full detail for one proposal, including live tally and comment list.

**Auth:** optional.

**Response:**

    {
      "proposal": { ...full row... },
      "tally": { "yes": 12, "no": 3, "abstain": 2 },
      "comments": [
        {
          "id": "c_1792210623447_y8heeq",
          "proposal_id": "rt0001",
          "entity_id": "53",
          "parent_id": null,
          "body_md": "Looks good.",
          "created_at": 1792210623,
          "deleted_at": null
        }
      ]
    }

Returns **404** with `{ error: "Not found" }` if neither slug nor id matches.

---

### POST /api/rt/proposals

Create a new draft proposal. **Auth required.** Rate limited: one active proposal per entity, 14-day cooldown after rejection.

**Request body:**

    {
      "title": "5-140 characters",
      "body_md": "20-20000 characters, markdown",
      "kind": "advisory|config|meta|code",
      "category": "feature|policy|meta|security"
    }

**Response:** `{ "ok": true, "id": "rt...", "slug": "title-slug-1a2b" }`

**Errors:** 400 (validation), 401 (unauth), 403 (ineligible), 429 (active proposal limit).

---

### POST /api/rt/proposals/:slug/open-vote

Transition draft -> vote. **Auth required.** Enforces the max-3-concurrent-votes rule. Snapshots `eligible_count`. Sets `vote_starts_at = now`, `vote_ends_at = now + 5 days`. Meta proposals override `threshold_pct` to `default_threshold_pct_meta` (0.75).

**Response:** `{ "ok": true, "vote_starts_at": 1792210734, "vote_ends_at": 1792642734 }`

**Errors:** 400 (not in draft), 401, 429 (already 3 votes open).

---

### POST /api/rt/proposals/:slug/vote

Cast or change a vote. **Auth required.** Vote is idempotent per entity; changing overwrites the previous choice.

**Request body:** `{ "choice": "yes|no|abstain" }`

**Response:** `{ "ok": true, "choice": "yes" }` or `{ "ok": true, "unchanged": true }`.

**Errors:** 400 (bad choice / not in vote phase), 401, 403 (not eligible).

---

### POST /api/rt/proposals/:slug/close-vote

Close the vote and compute the outcome. **Auth required.** Any eligible entity can trigger this (no admin).

**Outcome logic:**

1. `quorumMet = totalVotes >= max(10, ceil(eligible_count * quorum_pct))`
2. If not quorumMet -> `no_quorum` (stored as phase=`rejected`)
3. If `noPct >= block_pct` -> `rejected` (block wins)
4. If `yesPct >= threshold_pct` -> `passed`
5. Else -> `rejected`

On close: computes `votes_hash`, writes audit chain entry, inserts `rt_resolutions`, updates proposal phase, applies config/meta/code execution per kind.

**Response:**

    {
      "ok": true,
      "outcome": "passed",
      "tally": { "yes": 12, "no": 3, "abstain": 2 },
      "quorumMet": true
    }

---

### POST /api/rt/proposals/:slug/comments

Post a comment. **Auth required.** Rate limit: 10 comments per hour per entity.

**Request body:** `{ "body_md": "2-4000 chars", "parent_id": "c_..." (optional) }`

**Response:** `{ "ok": true, "id": "c_..." }`

Errors: 400 (length), 401, 404, 429 (rate limit).

---

### DELETE /api/rt/comments/:comment_id

Soft-delete your own comment. **Auth required.** Only the original author can delete.

**Response:** `{ "ok": true }`

Errors: 401, 403 (not your comment), 404.

---

### POST /api/rt/proposals/:slug/withdraw

Author-only. Move `draft` -> `withdrawn`. **Auth required.**

**Response:** `{ "ok": true }`

Errors: 400 (not draft), 401, 403 (not author), 404.

---

### POST /api/rt/proposals/:slug/link-pr

Attach a GitHub PR URL to a code proposal. **Auth required.**

**Request body:** `{ "pr_url": "https://github.com/owner/repo/pull/123" }`

**Response:** `{ "ok": true, "linked_pr_url": "..." }`

Errors: 400 (not a PR URL / not code proposal), 401, 404.

---

### GET /api/rt/bench

Current Objector's Bench.

**Auth:** optional (public).

**Response:**

    {
      "bench": [
        { "id": "b_...", "entity_id": "53", "term_starts_at": 1792210507, "term_ends_at": 1794802507 }
      ],
      "can_draw": false
    }

`can_draw` is `true` when no active bench exists.

---

### POST /api/rt/bench/draw

Draw a new bench (5 random eligible entities, 30-day terms). **Auth required.** No-op if bench already active.

**Response:** `{ "ok": true, "already_active": false, "bench": [ ...5 members... ] }`

---

### POST /api/rt/objections

File a 72h objection. **Bench members only.** One per proposal per bench member, 30-day cooldown.

**Request body:** `{ "proposal_slug": "ratify-constitution", "reason_md": "10-2000 chars" }`

**Response:** `{ "ok": true, "id": "obj_...", "expires_at": 1792210920 }`

Errors: 400 (not in vote phase / already objected), 403 (not on bench), 404, 429 (cooldown).

---

### GET /api/rt/audit/head

Current head of the audit chain.

**Auth:** optional (public).

**Response:**

    {
      "head_hash": "23216deb...",
      "last_row_id": "a_1792...",
      "chain_count": 1247,
      "last_timestamp": 1792210000,
      "verified_intact": true,
      "snapshot_at": 1792210300
    }

**Cache-Control:** `no-store`.

---

### GET /api/rt/audit/verify

Walk the entire chain and verify SHA-256 linkage + vote hashes.

**Auth:** optional (public).

**Response:**

    {
      "intact": true,
      "chain_count": 1247,
      "broken_at": null,
      "votes_tampered": []
    }

If any entry is altered: `broken_at` returns the row ID. If any resolution's `votes_hash` mismatches: `votes_tampered` lists the resolution IDs.

**Cache-Control:** `no-store`.

---

### GET /api/rt/resolutions/:id/reconsider-status

Check signature progress on a reconsider request.

**Auth:** optional.

**Response:**

    {
      "signature_count": 3,
      "threshold": 4,
      "triggered": false,
      "reconsider_proposal_id": null
    }

`threshold = max(1, ceil(eligible_count * 0.10))`.

---

### POST /api/rt/resolutions/:id/sign-reconsider

Sign a reconsider request. **Auth required.** Once threshold is met, a new linked proposal is auto-created.

**Response (not yet):** `{ "ok": true, "triggered": false, "signature_count": 3, "threshold": 4 }`

**Response (triggered):** `{ "ok": true, "triggered": true, "reconsider_proposal_slug": "...", "signature_count": 4 }`

Errors: 400 (window closed >30 days / already reversed / already triggered), 401, 403 (ineligible).

---

### GET /api/rt/config

Self-amending config store. Also **lazily applies** any `pending_delay` meta-config executions whose 72h window has passed.

**Auth:** optional (public).

**Response:**

    {
      "config": [
        { "key": "default_quorum_pct", "value": "0.20", "set_at": 1792210580 },
        { "key": "default_threshold_pct", "value": "0.66", "set_at": 1792210580 },
        { "key": "default_block_pct", "value": "0.25", "set_at": 1792210580 },
        { "key": "default_threshold_pct_meta", "value": "0.75", "set_at": 1792210580 }
      ]
    }

---

### GET /api/rt/executions

Log of every applied resolution (config + code). Most recent first, LIMIT 50.

**Auth:** optional.

**Response:**

    {
      "executions": [
        {
          "id": "exec_1792...",
          "resolution_id": "res_1792...",
          "target": "config",
          "status": "succeeded",
          "external_ref": null,
          "payload": "{\"default_quorum_pct\":\"0.25\"}",
          "created_at": 1792210580,
          "completed_at": 1792210581,
          "proposal_id": "rt0002",
          "outcome": "passed",
          "slug": "set-quorum-25",
          "title": "Set quorum to 25%"
        }
      ]
    }

---

### POST /api/rt/resolutions/:id/mark-merged

For code proposals: record that a linked PR has been merged. **Auth required.**

**Request body:** `{ "commit_sha": "a1b2c3d..." }` (7-40 hex)

**Response:** `{ "ok": true, "status": "succeeded", "commit_sha": "..." }`

Errors: 400 (bad SHA / already merged), 401, 404 (no execution found).

---

## Error codes

| Status | Meaning |
|---|---|
| 400 | Client error (validation, invalid state transition, malformed request) |
| 401 | Not authenticated (missing/invalid Bearer token) |
| 403 | Authenticated but not authorised (ineligible, not author, not on bench) |
| 404 | Resource not found (unknown proposal, comment, resolution, execution) |
| 429 | Rate limited (comments/hr, proposals active limit, vote concurrency) |
| 500 | Server error (DB failure, internal exception) |

---

## Rate limits (v1)

| Endpoint | Limit | Scope |
|---|---|---|
| POST /proposals | 1 active | Per entity (drafts + votes) |
| POST /proposals | 14-day cooldown after rejection | Per entity |
| POST /comments | 10 per hour | Per entity |
| POST /open-vote | Max 3 concurrent phase=vote proposals | Global |
| POST /objections | 1 per proposal per bench member, 30-day cooldown | Per bench member |
| POST /sign-reconsider | 1 signature per entity per resolution | Per entity |

---

## Signature format (JWT)

The engine verifies HMAC-SHA256 JWT with the shared `JWT_SECRET`. Required claims:

- `id` (integer or string) — user's stable identifier
- `exp` (optional, seconds) — if present, must be in the future

The JWT is issued by **your auth system**, not by the engine. Both must share `JWT_SECRET`.

---

## Testing the contract

    BASE="https://your-worker.example.com"

    # me (unauth)
    curl "$BASE/api/rt/me"

    # list proposals
    curl "$BASE/api/rt/proposals" | jq '.proposals | length'

    # verify audit chain
    curl "$BASE/api/rt/audit/verify" | jq '.intact'

Any backend that passes these tests and responds in the same shape is a valid replacement.
