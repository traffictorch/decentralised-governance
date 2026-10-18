# Roadmap

## v1.0 — Shipped

- [x] Identity & eligibility
- [x] Vote API (open / cast / close / tally)
- [x] Discussion (threaded comments)
- [x] Proposal authoring
- [x] Objector Bench (sortition, 72h pause)
- [x] Audit chain (SHA-256 linked)
- [x] Reconsider window (10%, 30 days)
- [x] Config execution (self-amending thresholds)
- [x] Code proposal advisory (linked PR tracking)
- [x] 5-scenario simulator (portable, vanilla JS)
- [x] Governance docs as markdown templates
- [x] Daily external audit-chain snapshot (GitHub Action)

## v1.1 — Near-term polish

- [ ] 3 example demos (standalone, Tailwind, plain CSS) fleshed out
- [ ] Full API contract document
- [ ] Porting guide: Node+Postgres, Supabase, Lambda+DynamoDB
- [ ] init.sh scaffolder
- [ ] WebAuthn passkey scaffolding (optional, disabled by default)

## v2 — Deferred (speculative)

- [ ] Conviction voting (longer commitment = more weight, capped)
- [ ] Commit-reveal votes (bribery-resistant, at auditability trade-off)
- [ ] Futarchy-lite forecaster (advisory prediction markets)
- [ ] GitHub App auto-merge flow (HMAC + CI webhook)
- [ ] Automated sunset (resolutions expire after 12 months unless renewed)
- [ ] Anonymous-vote mode as per-proposal opt-in

## Not on the roadmap

- Blockchain, tokens, gas fees, speculation
- Admin override mechanisms
- Anonymous default voting
- Anything requiring a specific cloud provider
