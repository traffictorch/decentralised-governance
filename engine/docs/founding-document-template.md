# Founding Document — [PROJECT_NAME]

## The short version

On **[YYYY-MM-DD]**, the maintainer seeded **7 proposals** into a fresh database. These are the founding rules. All 7 are in phase `draft` with `author_entity_id = 'system'`.

## Why seed at all

A voting system needs rules before it can vote. Rules need proposals. Proposals need a mechanism that does not exist until the rules exist. Bootstrap problem.

Solution: seed the minimum viable ruleset, then hand control to the community. Every seeded proposal is real — votable, challengeable, rejectable.

## The 7 founding proposals

| ID | Purpose |
|---|---|
| rt0000 | Ratify the complete ruleset |
| rt0001 | Define "Entity" |
| rt0002 | Set default thresholds |
| rt0003 | Establish the Objector's Bench |
| rt0004 | Define the Execution Bridge |
| rt0005 | The Reconsider Window |
| rt0006 | Reserved for community's first decision |

## How to challenge them

1. Log in with an eligible account.
2. Open any founding proposal.
3. Vote **NO** — public, on the record, permanent.
4. If 25%+ say NO, the proposal fails.
5. Or draft a replacement once eligible.

## What the maintainer can and cannot do

**Can:** deploy code, restart the worker, add features, merge PRs after votes pass.

**Cannot:** override a vote, remove a resolution from history, hide a comment (only authors can delete their own), change a vote tally after close.

The audit chain at `/api/rt/audit/verify` proves the last three.

## How to verify

    wrangler d1 execute <YOUR_DB_NAME> --remote \
      --command "SELECT id, slug, author_entity_id, created_at FROM rt_proposals ORDER BY id"

All 7 show `author_entity_id = 'system'` and identical `created_at`.
