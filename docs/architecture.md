# Architecture

## The system in one diagram

    +--------------------------------------------------------------+
    |                    USER (browser or app)                     |
    |  - Alpine or plain JS frontend                               |
    |  - Reads state from API, sends signed votes                  |
    +------------------------------+-------------------------------+
                                   | HTTPS + Bearer JWT
                                   v
    +--------------------------------------------------------------+
    |                AUTH LAYER (your existing system)             |
    |  - Issues JWTs to logged-in users                            |
    |  - Shares JWT_SECRET with the governance worker              |
    +------------------------------+-------------------------------+
                                   v
    +--------------------------------------------------------------+
    |           GOVERNANCE WORKER (this engine)                    |
    |  - Route handler (worker.js -> round-table.js)               |
    |  - verifyJWT: proves identity                                |
    |  - State machine: enforces draft -> vote -> resolved         |
    |  - Audit chain: SHA-256 linked writes                        |
    |  - Config applier: self-amending rules                       |
    +------------------------------+-------------------------------+
                                   v
    +--------------------------------------------------------------+
    |                  D1 (or any SQL database)                    |
    |  rt_proposals, rt_votes, rt_comments, rt_resolutions,        |
    |  rt_entities, rt_bench, rt_objections, rt_audit_chain,       |
    |  rt_config, rt_executions, rt_reconsiders,                   |
    |  rt_reconsider_signatures, rt_audit_checkpoints, users       |
    +------------------------------+-------------------------------+
                                   v (daily snapshot)
    +--------------------------------------------------------------+
    |         EXTERNAL AUDIT ANCHOR (GitHub Action)                |
    |  - Fetches /api/rt/audit/head every day at 00:00 UTC         |
    |  - Commits snapshot to a public repo                         |
    |  - Makes chain tampering detectable, not preventable         |
    +--------------------------------------------------------------+

## Components

**worker.js** — HTTP router + JWT verifier + CORS. Thin layer that hands everything under `/api/rt/*` to `round-table.js`. This is the piece adopters customise (CORS origin, auth scheme, extra routes).

**round-table.js** — all governance logic. Routes, state transitions, tally computation, audit chain, config applier. Do not edit unless extending the engine itself.

**schema.sql** — 13 D1 tables. Idempotent CREATE TABLE IF NOT EXISTS.

**seed-proposals.sql** — 7 bootstrap proposals. Idempotent INSERT OR IGNORE.

**engine/simulator/** — 3 files, no dependencies. Pure vanilla JS + CSS. Not part of the governance engine; an explanatory demo.

## The trust boundaries

The system has **three** trust boundaries. Each is disclosed in the constitution (Article 9).

**1. Authentication.** The engine trusts the JWT issued by your auth worker. If an attacker compromises the auth worker, they can forge any identity. Mitigation: standard auth hardening.

**2. The database.** The engine trusts D1 (or your DB). Anyone with direct DB write access can mutate the audit chain, but the next verification will detect it. Mitigation: no out-of-band DB writes; daily external snapshots; least-privilege DB credentials.

**3. Deployment.** The engine trusts whoever can deploy `worker.js`. A malicious deploy could return fake results. Mitigation: code review, deployment audit log, daily snapshots.

**The engine does not eliminate these boundaries. It makes their exercise visible.** That's the entire point of the audit chain — you can't prevent a DB administrator from tampering, but you can make the tampering provable.

## The audit chain

Every write to `rt_proposals`, `rt_votes`, `rt_comments`, `rt_resolutions` also appends a row to `rt_audit_chain`:

    row_id       = 'a_' + timestamp + '_' + random
    table_name   = 'rt_votes' (etc)
    action       = 'insert' | 'update' | 'delete'
    payload      = JSON.stringify({ the row's data })
    prev_hash    = previous row's this_hash
    this_hash    = SHA256(prev_hash + '|' + table_name + '|' + action + '|' + payload)

The chain is append-only by policy, not by database constraint. If anyone deletes a row from `rt_audit_chain`, the next verification returns `intact: false` at that row.

**External anchor.** A GitHub Action runs daily at 00:00 UTC, fetches `GET /api/rt/audit/head`, and commits the result to `audit-history/YYYY-MM-DD.json` in the adopter's repo. This doesn't prevent tampering — it creates an immutable external record of what the chain head was on each day. If an attacker rewrites the whole chain, the current head won't match historical snapshots.

## The config store

`rt_config` holds self-amending thresholds and flags:

- `default_quorum_pct` — default quorum for new proposals
- `default_threshold_pct` — default pass threshold
- `default_block_pct` — default block threshold
- `default_threshold_pct_meta` — threshold for meta proposals

Read at **proposal creation time**. When a `config` proposal passes, its body is parsed for `SET key=value` lines, and those keys are written immediately. When a `meta` proposal passes with `SET` directives, the execution is queued with `status=pending_delay` for 72h. On any subsequent `/config` GET, the endpoint checks for due delays and applies them.

**Consequence:** the community can change its own quorum/threshold by vote. The rules are not fixed in code — they are data in `rt_config`.

## The state machine

    draft    -> vote       (via /open-vote)
    draft    -> withdrawn  (via /withdraw)
    vote     -> passed     (via /close-vote, outcome=passed)
    vote     -> rejected   (via /close-vote, outcome=rejected|no_quorum)
    passed   -> reversed   (via /close-vote on a linked reconsider)

Attempting any other transition -> HTTP 400. The worker enforces this — there is no way to skip phases.

## Extending

**To port to another stack**, keep the HTTP contract identical (`docs/api-contract.md`) and reimplement the state machine + audit chain logic in your language. The Cloudflare worker is ~750 lines — a direct port is 3-5 days for one developer.

**To add a new proposal kind**, add it to the kind enum validation in create-proposal, and add handling in close-vote for the new kind's execution semantics.

**To change consensus rules**, do not edit code. Submit a `meta` proposal with `SET` directives that adjust the relevant `rt_config` keys. The system is designed to amend itself.

## What's not here

- No blockchain, no tokens, no gas fees. This is a database and an HTTP API.
- No admin override. If you need admin power, extend `round-table.js` — but that removes the "no admin" guarantee the constitution promises.
- No anonymous voting. Every vote is attributable to an entity. This is deliberate (auditability > privacy).
