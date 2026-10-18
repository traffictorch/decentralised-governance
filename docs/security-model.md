# Security Model

An honest threat model. What can go wrong, what the engine does about it, what it doesn't.

## The three trust boundaries

The engine trusts three things outside itself:

1. **Your auth system** — it verifies JWTs signed with `JWT_SECRET`. If your auth is compromised, identity is forgeable.
2. **Your database** — direct DB access can mutate state, including the audit chain. Detection, not prevention, is the model.
3. **The deploy pipeline** — whoever deploys `worker.js` can return false results. Code review + deployment audit logs are the mitigation.

The engine's job is not to eliminate these. It's to **make their exercise visible.**

## Threats and mitigations

### Sybil attacks — many identities, one human

**Attack:** Attacker creates many accounts to swing a vote.

**Mitigations in v1:**
- Account must be ≥7 days old before voting
- Eligibility snapshot at vote-open (no last-minute account creation)
- Profile verification (`verified_at`) or public profile required
- Passkey support (reserved for v2) will make this stronger

**Residual risk:** With a weak auth system (email + password only), a determined attacker can mass-register. **The engine cannot fix weak authentication.** Deploy only on an auth system you trust.

### Bribery and vote buying

**Attack:** Paying voters for a choice, in or out of band.

**Mitigations:**
- Votes are public — bribery is visible, but so is voting.
- Casting a vote that changes later is possible until close (deters some scenarios, not all).
- Commit-reveal (v2) would remove post-hoc proof of how someone voted — this is the strongest known defense.

**Residual risk:** Public votes make bribery **provable**, which is also its weakness. Anyone buying votes can verify they were cast. This is a real trade-off. If bribery is a serious concern in your community, vote for the commit-reveal v2 feature — but understand the auditability cost.

### Whale capture — one rich member dominates

**Attack:** A single entity buys or controls many accounts (see Sybil) or captures the majority of the electorate.

**Mitigations:**
- Equal authority — every entity has exactly one vote, regardless of stake
- Block threshold (25% NO) — a bare majority can't override a substantial minority

**Residual risk:** If a whale controls >75% of eligible entities, they effectively control outcomes. The only defense is **keeping the eligible pool diverse and large** — this is a community problem, not a code problem.

### Admin capture

**Attack:** Someone with deploy/DB access grants themselves special powers.

**Mitigations:**
- No admin table exists. Code paths can't reference one.
- The maintainer powers page discloses what the maintainer can/cannot do.
- Daily external snapshots of the audit chain head make silent rewrites detectable.

**Residual risk:** A deploy-time change could add an admin table. **The repo is a template — you must verify your own deploy.** Fork + audit + rebuild if trust is broken.

### Collusion

**Attack:** Groups coordinate votes off-platform.

**Mitigations:** None at the protocol level. Coordination is a normal part of politics. The transparency of voting is designed to make collusion **visible**, not impossible.

**Residual risk:** Persistent.

### Flash brigading

**Attack:** Lots of voters appear at the last minute.

**Mitigations:**
- Eligibility snapshot at vote-open — no new voters can join the pool after voting starts.

**Residual risk:** Low, given account-age gating.

### Objector's Bench griefing

**Attack:** A bench member files repeated objections to stall votes indefinitely.

**Mitigations:**
- One objection per proposal per bench member (v1.0 rule)
- 30-day cooldown after filing
- 72-hour max pause per objection
- Bench terms are 30 days — not renewable

**Residual risk:** Low. Worst case is one 72-hour delay per proposal per bench member.

### Audit chain tampering

**Attack:** Someone with DB access updates or deletes chain entries.

**Mitigations:**
- Each entry's `this_hash` covers the previous entry's `this_hash` (SHA-256 chain)
- `/api/rt/audit/verify` reports the exact broken row
- `votes_hash` on each resolution independently verifies the vote set hasn't been altered

**Residual risk:** An attacker who can update **every** row in `rt_audit_chain` and knows the algorithm can rebuild a valid chain. The **external daily snapshot** (GitHub Action) is the defense — a rebuilt chain won't match historical snapshots committed to a public repo.

## What the engine cannot protect against

- **Compromised JWT secret.** Rotate `JWT_SECRET` immediately if exposed. All sessions become invalid.
- **A malicious deploy.** Code review is the only mitigation.
- **Denial of service.** Use Cloudflare's standard protections.
- **Legal coercion.** The maintainer's real-world identity is public; that's a feature and a risk.

## Reporting vulnerabilities

Open a confidential GitHub Security Advisory. Do not open a public issue for a live vulnerability.
