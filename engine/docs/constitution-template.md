# The Constitution of [PROJECT_NAME]

**Version:** 1.0 (Draft — pending ratification)
**Published:** [YYYY-MM-DD]

## Preamble

We, the entities of [PROJECT_NAME], establish this Constitution to:

- Guarantee that every eligible member has equal voice.
- Ensure every decision is recorded in a way that cannot be silently rewritten.
- Protect minority positions from being overruled by a bare majority.
- Make the rules themselves amendable by the same process they govern.
- Disclose honestly where power still exists outside the system.

This document is not fixed. It is the current state of an evolving agreement.

## Article 1 — Equal Authority

**1.1** Every eligible entity has exactly one voice.

**1.2** No entity can override another entity's vote, comment, proposal, or resolution.

**1.3** No administrator role exists inside the system. There is no account with special voting weight, no secret override, no hidden veto. This is enforced by the database schema — no admin table exists.

**1.4** Entities found to circumvent this Article through deception, bots, or impersonation may be suspended by the community's normal voting process, not by any individual.

## Article 2 — The Entity

**2.1** An *entity* is a registered account that:

- (a) is at least 7 days old,
- (b) has made at least one prior community action, and
- (c) is operated by a human being.

**2.2** Bots and AI agents are not entities unless the community explicitly authorizes them by Meta proposal.

**2.3** Eligibility is snapshotted at the moment a vote opens. Entities who join later cannot vote on that proposal.

## Article 3 — The Vote

**3.1** Voting is public. Every entity's choice is visible on the proposal page.

**3.2** A vote is changeable until the vote closes. The final choice stands.

**3.3 — Quorum.** A vote is valid only if at least 20% of eligible entities participate, with a floor of 10 votes.

**3.4 — Pass threshold.** Ordinary proposals pass at 66% YES. Meta proposals pass at 75% YES.

**3.5 — Block threshold.** A proposal fails if 25% or more of votes cast are NO, regardless of YES percentage. Block beats pass.

**3.6 — Abstain is not No.** Abstain counts toward quorum but not toward the pass threshold.

**3.7 — Comment periods.** Meta proposals require 30 days of comment before voting opens. Config 14 days. Advisory 7 days.

## Article 4 — The Objector's Bench

**4.1** Five entities are randomly selected by sortition to serve 30-day terms.

**4.2** Any Bench member may file an objection during an open vote, pausing it 72 hours. Reason must be public.

**4.3** A Bench member can file only one objection per proposal, with a 30-day cooldown.

**4.4** The Bench can only slow a vote. It cannot pass, block, or alter any proposal.

## Article 5 — The Reconsider Window

**5.1** Any resolution may be reopened within 30 days of its decision.

**5.2** A reconsider is triggered when 10% of eligible entities sign a written request.

**5.3** A reconsider opens a new vote on the same question under the same rules.

**5.4** If the reconsider reverses the outcome, the original resolution is marked *reversed*. Nothing is deleted.

## Article 6 — Execution

**6.1** A vote records intent. It never writes code directly.

**6.2** Config proposals take effect immediately on pass.

**6.3** Meta proposals changing rules or thresholds take effect 72 hours after passing, allowing the reconsider window to fire first.

**6.4** Code proposals require a linked pull request. A human reviewer merges the PR. The merge SHA is recorded on the audit chain.

## Article 7 — The Audit Chain

**7.1** Every vote, comment, proposal, and resolution is recorded in an append-only chain, SHA-256 linked with the previous entry.

**7.2** Anyone can verify the chain at `/api/rt/audit/verify`. Any alteration returns `intact: false` with the exact broken row.

**7.3** A snapshot of the chain head is published daily to a public repository.

**7.4** The chain cannot detect a full-history rewrite by an operator controlling both the database and every external snapshot.

## Article 8 — Amending This Constitution

**8.1** This Constitution is itself a Meta proposal, amendable by the process it defines.

**8.2** An amendment must pass at 75% YES, face fewer than 25% NO, and survive the 72-hour apply delay.

**8.3** Amendments are recorded permanently. The preamble, Articles, and every clause are equally amendable. Nothing is carved out.

## Article 9 — Honest Disclosures

**9.1** The maintainer holds infrastructure authority: deploys, database access, and merge rights. See Maintainer Powers.

**9.2** The audit chain runs on a single server. External snapshots help detect tampering, not prevent it.

**9.3** Votes are public and subject to social pressure. Deliberate trade-off.

**9.4** The maintainer role is not elected. No process currently exists to rotate or remove the maintainer by community decision.

## Article 10 — Ratification

**10.1** This Constitution takes effect the day it passes its first ratifying vote.

**10.2** Prior to ratification, decisions made under the 7 founding proposals stand as valid bootstrap decisions.

**10.3** After ratification, any conflict with an earlier founding proposal is resolved in favor of this document.

*Signed into effect on the date of the first successful ratifying vote.*
