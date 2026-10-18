# Cadence Rules

The schedule the community operates on. All values are stored in `rt_config` and are **amendable by Meta proposal**.

## No scheduled decisions

Proposals move at their own phase pace. There is no "vote every month" — a proposal opens a vote when its author calls `open-vote` and the phase transition is valid.

## Max 3 concurrent votes

At most 3 proposals can be in `phase = vote` at any moment. Prevents voter fatigue.

## Round Table Day

**First Monday of every month.** A retrospective window for:

- What passed last month
- What got executed
- What's broken
- The reconsider window for anything from the prior 30 days

Not a voting day — a review day.

## Auto-close

Votes hard-close 5 days after they open, per kind:

- Meta: 5 days vote
- Config: 5 days vote
- Advisory: 5 days vote

No extensions. The rules apply to everyone.

## Comment periods (before voting opens)

- Meta: 30 days
- Config: 14 days
- Advisory: 7 days

## Sunset (v2)

Every non-meta resolution expires after 12 months unless renewed by re-vote. Prevents cruft. Not in v1.

## Reconsider window

30 days from resolution. 10% of eligible entities can trigger a re-vote.

## Proposals you can have open

- **1 active proposal per entity** (drafts + votes count as active)
- **14-day cooldown** after a rejection before submitting again
