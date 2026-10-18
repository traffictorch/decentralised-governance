# Governance 101

Why the system is designed this way. This document assumes no prior governance theory.

## The problem with polls

A poll records opinion. A vote **commits** the community to an action. The difference is enforcement. If 60% of respondents want a feature and the maintainer builds it, that's not governance — that's a strong suggestion. Real governance has three properties:

1. **Binding** — a passed resolution obligates the community to a course of action.
2. **Auditable** — anyone can verify the outcome was computed correctly.
3. **Reversible** — if the decision turns out to be wrong, the same process can undo it.

The engine provides all three.

## Why equal authority

The engine has **no admin table** by design. This is not a philosophical stance — it's structural. If an admin override exists in the schema, someone will eventually use it. Removing the table means the codepath cannot exist.

Consequence: if the community makes a catastrophic decision, the only correction path is another vote. The mitigation is the **block threshold** (see below) — it stops the worst decisions before they pass.

## Why a block threshold (25% NO)

A simple majority system (51% passes) is famously unstable: 51% can oppress 49% indefinitely. The block threshold means **25% NO** vetoes the outcome regardless of the YES percentage.

Effect:
- A proposal that 66% YES, 24% NO passes
- A proposal that 74% YES, 26% NO **fails**
- A proposal that 51% YES, 49% NO fails (49% > 25%)

This trades some efficiency for durable legitimacy. If you can't get to 75% YES without 25% NO, the community doesn't have real consensus — just a majority.

## Why sortition (the Objector's Bench)

Sortition — random selection — was used in Athens to fill governing bodies. It avoids the professionalization of politics: no one can run for the Bench, so no one can campaign for it, so no one can be captured. Five random entities per 30-day term, one objection each, 72-hour pause.

**Why it can only pause, not block:** if the Bench could block, it would be an oligarchy of five. Pausing is enough to force reflection without granting power.

## Why the reconsider window (30 days, 10%)

Every decision is provisional for 30 days. If 10% of eligible entities sign a reconsider request, a new vote opens. This catches two failure modes:

1. **Regret.** A decision that looked good in the moment turns out to be bad — often only visible after a week or two of lived experience.
2. **Rushed voting.** A proposal that passed with a bare majority during low turnout can be re-examined when people are paying attention.

The 10% threshold is deliberately low — easy to trigger, hard to abuse. A community that reconsiders everything learns which decisions were genuinely wrong.

## Why execution is separate from voting

A vote records **intent**. It does not write code. This is critical because:

- **Code is different from policy.** Policy can be applied instantly. Code needs review.
- **Bugs exist.** A malicious or buggy PR that auto-merged could break the whole system.
- **Human review is a required step.** The merge SHA is recorded on the audit chain — so even the merge is auditable.

This boundary is disclosed. It's also the reason a passed code proposal can sit as `pending_merge` for days or weeks: a maintainer has to actually merge the PR.

## Why the audit chain

Trust in a governance system comes from **verifiability**, not from trusting the operators. The audit chain makes every write visible. If someone tampers, the tamper becomes visible to anyone who runs `/api/rt/audit/verify`.

The chain does **not** prevent tampering. It makes tampering **provable**. That's the strongest practical guarantee a self-hosted system can give — because the operator of the system is exactly the party whose actions you want to verify.

## What this is not

- **Not a DAO.** No tokens, no gas fees, no blockchain. A database and an HTTP API.
- **Not a promise of perfect democracy.** It's a tool. Its effectiveness depends on who participates, how often, and whether they care.
- **Not a replacement for legitimacy.** A governance system that nobody uses produces decisions that nobody respects. The rules only matter if the community is engaged enough to invoke them.

## How to use it well

1. **Propose carefully.** Spend the comment period editing the proposal based on feedback.
2. **Vote on everything.** Quorum failures hurt everyone.
3. **Vote NO when you mean it.** Abstain is for "I don't have a view", not "I disagree but don't want to be quoted."
4. **Use reconsider sparingly.** It's a safety net, not a veto.
5. **Read the audit chain.** It's public. Use it.
