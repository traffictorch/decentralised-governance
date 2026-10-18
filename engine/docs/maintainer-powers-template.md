# Maintainer Powers — [PROJECT_NAME]

The complete, honest list of what the site maintainer can and cannot do inside the governance system.

## Who is the maintainer

[MAINTAINER_NAME] — creator of [PROJECT_NAME], operator of the infrastructure, holder of the deploy and merge buttons.

The maintainer role is **bootstrap**. There is no election mechanism yet. This is a disclosed limitation.

## What the maintainer CAN do

- Deploy code — push changes to production.
- Deploy the governance worker.
- Access the database directly — any SQL including UPDATE/DELETE.
- Merge pull requests on the code repository.
- Add features and deploy new functionality.
- Rotate secrets (JWT_SECRET, API keys).
- Trigger the bench draw.

## What the maintainer CANNOT do (with proof)

### Cannot override a vote

A cast vote writes a row to `rt_votes` and inserts into `rt_audit_chain`. The maintainer *could* run UPDATE SQL directly — but the chain's SHA-256 hash covers the vote's payload. Any change breaks the chain for that entry and every subsequent one. `/api/rt/audit/verify` reports `intact: false` with the exact broken row.

### Cannot remove a resolution

Every resolution writes a chain entry with `prev_hash -> this_hash`. Deleting a resolution breaks the link to the next entry. Daily external snapshots committed to the code repository record the historical head.

### Cannot hide a comment they don't own

Comments can only be soft-deleted by their author. The maintainer could theoretically UPDATE `deleted_at` on another user's comment — but disclosed here, not hidden.

### Cannot change a vote tally after close

Closing a vote writes a `votes_hash` to `rt_resolutions` — a SHA-256 of the exact vote set. Anyone can recompute this hash from `rt_votes` and compare.

## Known limitations

- Audit chain doesn't cover maintainer SQL writes.
- Maintainer role is not elected.
- The chain runs on our server. External daily snapshots detect but don't prevent rewrites.
- Vote privacy: votes are public by design. Coercion risk is real.

## Community recourse

If the maintainer goes rogue:

1. **Fork the repository.** Every line of code, schema, and audit pattern is public.
2. **Verify the chain first.** `curl <URL>/api/rt/audit/verify` before believing accusations.
3. **Check historical snapshots.** Compare current vs prior `audit-history/` files.
4. **Propose a change.** The system itself is the mechanism for fixing governance problems.
