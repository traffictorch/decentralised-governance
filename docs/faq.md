# FAQ

## What is this, really?

A self-hosted governance system. You deploy a Cloudflare Worker + a D1 database. Your community uses a frontend you build (or copy from `examples/`) to propose, discuss, vote, and audit decisions.

## How do I deploy it?

See the README's "Install in 2 minutes". Five commands from a fresh clone to a live API.

## Do I need a blockchain?

No. It's a SQLite-backed HTTP API. The tamper-evidence comes from SHA-256 hashing, not from a distributed ledger.

## Do I need tokens?

No.

## Who can vote?

Registered users who meet the eligibility criteria: account age >= 7 days, human-operated. See `docs/api-contract.md` for the exact rules.

## Can I change the thresholds?

Yes. Submit a `meta` proposal with `SET default_threshold_pct=0.70` in the body. If it passes with 75% YES, the new threshold applies to future proposals. Meta changes take effect 72 hours after passing, so the reconsider window can fire.

## Can an admin override a vote?

No admin table exists. There is no code path that grants special voting weight, veto power, or result tampering. The maintainer can deploy malicious code that changes this — that's disclosed in `docs/security-model.md`.

## What if the maintainer goes rogue?

Fork the repo. The schema, code, audit chain pattern, and historical snapshots are all public. A community fork can restart from the same rules. This is why it's MIT licensed.

## What's the Objector's Bench?

Five randomly-selected entities with 30-day terms. Each can file one objection per proposal, pausing it 72 hours. It's a circuit breaker, not a veto. See `docs/governance-101.md`.

## How do I verify the audit chain?

`curl https://your-worker.example.com/api/rt/audit/verify` returns `{ intact: true/false, chain_count, broken_at }`. Anything other than `intact: true` means someone has modified data after the fact.

## How do I make the chain tamper-evident externally?

Enable the `.github/workflows/audit-head.yml` action. It commits a daily snapshot of the chain head to `audit-history/YYYY-MM-DD.json` in a public repo. If anyone rewrites the chain, the current head won't match historical snapshots.

## Can I run it on Vercel / Netlify / AWS / my own server?

Yes. Implement the API contract (`docs/api-contract.md`) in any stack. The Cloudflare Worker is 750 lines — a port is 3-5 days of work for one developer.

## Does it work with Postgres / MySQL / Supabase?

Yes. See `docs/porting-guide.md` (in this session's later blocks) for worked examples. The schema is standard SQL.

## What about anonymous voting?

Not supported. Votes are public by design. Anonymous voting is on the roadmap as a per-proposal opt-in — with the trade-off that bribery becomes harder to prove but coercion becomes harder to detect.

## What happens if nobody votes?

If quorum isn't met, the vote is `no_quorum` and the proposal is treated as rejected. No binding decision is made.

## Can I delete a proposal?

You can withdraw your own draft before voting opens. After voting starts, proposals cannot be withdrawn — the vote must run to completion (pass, reject, or no-quorum). This is deliberate: voters need stability.

## Can I change my vote?

Yes, until the vote closes. The final choice counts.

## Is the code audited?

The reference implementation in `engine/cloudflare/` has been deployed in production at traffictorch.net/community/round-table/. It hasn't had a formal third-party audit. The threat model is documented in `docs/security-model.md`. Use at your own risk.

## How do I contribute?

See `CONTRIBUTING.md`. Especially welcome: ports to other stacks, governance-theory corrections, security reviews, documentation improvements.

## Why is it licensed MIT (code) + CC BY-SA (docs)?

Code should be unencumbered — MIT maximizes adoption. Governance text should stay in the commons — CC BY-SA means forks of the rules remain forks of the rules. See `LICENSE` and `LICENSE-docs`.

## Is there a paid version?

No. This is the whole system. Nothing withheld.
