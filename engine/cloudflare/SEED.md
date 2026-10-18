# Founding Seed

The system ships with 7 bootstrap proposals so the community has something to vote on from day one.

## Why seed

A voting system needs rules before it can vote. Rules need proposals. Proposals need a mechanism that does not exist until the rules exist. Bootstrap problem. Seed the minimum viable ruleset, then hand control to the community.

## The 7 proposals

| ID | Slug | Purpose |
|---|---|---|
| rt0000 | ratify-constitution | The complete ruleset |
| rt0001 | define-entity | Eligibility criteria |
| rt0002 | default-thresholds | Quorum/pass/block numbers |
| rt0003 | objectors-bench | Sortition circuit breaker |
| rt0004 | execution-bridge | Config vs code execution |
| rt0005 | reconsider-window | Reopening decisions |
| rt0006 | first-feature | Reserved for community first decision |

## How to seed

    wrangler d1 execute <YOUR_DB_NAME> --remote --file=seed-proposals.sql

## Verify

    wrangler d1 execute <YOUR_DB_NAME> --remote \
      --command "SELECT id, slug, author_entity_id FROM rt_proposals ORDER BY id"

All 7 show author_entity_id = 'system' and identical created_at.

## Adapting

Do NOT remove the 7 founding proposals. Adapt the body text to your rules but keep the shape. If you drop the constitution proposal you lose the "rules that bind future rules" mechanism and the system becomes a poll, not a government.

Edit seed-proposals.sql bodies, replace placeholders, then run.
