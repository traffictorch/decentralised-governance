# The Audit Chain

Every write to a governance table also appends a row to `rt_audit_chain`. The chain is **append-only by policy**, SHA-256 linked, and independently verifiable.

## Structure

    row_id       = 'a_' + timestamp + '_' + random
    table_name   = 'rt_proposals' | 'rt_votes' | 'rt_comments' | 'rt_resolutions' | 'rt_objections'
    action       = 'insert' | 'update' | 'delete'
    payload      = JSON.stringify(row_data)
    prev_hash    = previous row's this_hash
    this_hash    = SHA256(prev_hash + '|' + table_name + '|' + action + '|' + payload)
    created_at   = unix seconds

The **first row's** `prev_hash` is the literal string `GENESIS`.

## Verification

`GET /api/rt/audit/verify` walks the chain from start to end:

    for each row:
        expected = SHA256(prev_hash + '|' + table_name + '|' + action + '|' + payload)
        if expected !== this_hash -> chain is broken at row_id
        if prev_hash !== last_seen_hash -> chain is broken at row_id
        last_seen_hash = this_hash

Response on intact chain:

    { "intact": true, "chain_count": 1247, "broken_at": null, "votes_tampered": [] }

Response on break:

    { "intact": false, "chain_count": 1247, "broken_at": "a_1792210000_abc123", "votes_tampered": [] }

## Vote hash verification

Each `rt_resolutions` row stores `votes_hash` = SHA256 of the ordered vote set at close:

    votes = SELECT entity_id, choice FROM rt_votes WHERE proposal_id = ? ORDER BY entity_id ASC
    expected = SHA256(JSON.stringify(votes))

`/api/rt/audit/verify` also recomputes this for every resolution. If the current votes no longer match, the resolution ID is listed in `votes_tampered`. This catches a scenario the chain alone wouldn't: someone directly editing `rt_votes` after a resolution closed. The chain has the resolution's hash; the current state doesn't match → detected.

## External anchor

The chain runs on **your server**. If an attacker compromises both the DB and the worker simultaneously, they could rebuild the chain from scratch. This is disclosed (constitution Article 7.4).

The mitigation is **daily external snapshots**. A GitHub Action:

1. Runs daily at 00:00 UTC
2. Calls `GET /api/rt/audit/head`
3. Commits the result to `audit-history/YYYY-MM-DD.json` in a public repo

Each snapshot contains:

    {
      "head_hash": "23216deb...",
      "last_row_id": "a_1792...",
      "chain_count": 1247,
      "last_timestamp": 1792210000,
      "verified_intact": true,
      "snapshot_at": 1792210300
    }

**What this detects:**
- A rewritten chain (current `head_hash` won't match any historical snapshot)
- A truncated chain (current `chain_count` < prior snapshot's `chain_count`)
- A backdated chain (current `last_timestamp` < prior snapshot's `last_timestamp`)

**What this does not detect:**
- An attacker who has controlled the DB since **before** the first snapshot was taken
- A coordinated rewrite + force-push to `audit-history/` (defend by making the audit repo immutable or mirrored to a third-party archive)

**What you should do:**
1. Fork `audit-history/` to a second GitHub account (independent anchor)
2. Enable branch protection on `audit-history/` after each snapshot commits
3. Optionally mirror to IPFS or a timestamping service for full tamper-resistance

## Checkpoints (v1.1)

The `rt_audit_checkpoints` table is reserved for periodic signed snapshots (every 1000 rows). Each checkpoint will store `{ last_row_id, last_hash, created_at }` and optionally an external signature. This makes verification O(checkpoint_interval) instead of O(chain_length) once chains grow past a few thousand rows.

**Status:** table exists; verification still walks the full chain in v1.0.

## What "tamper-evident" means

- If someone edits a chain entry, the next verify reports it.
- If someone deletes a chain entry, the next verify reports it (broken `prev_hash` link).
- If someone inserts a chain entry mid-chain, the next verify reports it.
- If someone rewrites the chain from genesis, external snapshots catch it (assuming they don't also rewrite every historical snapshot).

That's the guarantee: **not that tampering is impossible, but that tampering is visible to anyone who checks.**

## How to check independently

    # full verify
    curl https://your-worker.example.com/api/rt/audit/verify

    # current head
    curl https://your-worker.example.com/api/rt/audit/head

    # compare against historical snapshots
    ls audit-history/
    cat audit-history/$(date -v-1d +%Y-%m-%d).json

You don't need to trust the worker — the response is just numbers. Check the numbers against the snapshots yourself.
