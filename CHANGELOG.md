# Changelog

[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Semantic versioning.

## [1.1.0] — 2026-10-18

### Changed

- Simulator v2 — Mission Control rewrite (phase rail, chamber, tally, audit ticker, scrubber, sandbox)
- Extracted pure rules engine to governance-rules.js (browser + node + worker)
- Added 29-assertion test suite (governance-rules.test.mjs)
- 6 scenarios (was 5) — added no-quorum and bench-reconsider
- Scenario timelines are event data; engine computes every outcome
- Sandbox mode with URL state (s=sandbox, eligible, turnout, yes, no, kind)
- Live config fetch with Live / Default badge

## [1.0.0] — 2026-10-18

### Added

- Initial public release.
- Cloudflare Worker reference implementation (`engine/cloudflare/`)
- Merged D1 schema — fresh installs need only `schema.sql`
- 7 seeded founding proposals (`seed-proposals.sql`)
- Portable 5-scenario simulator (`engine/simulator/`, zero deps)
- Governance text templates (`engine/docs/`)
- MIT (code) + CC BY-SA 4.0 (docs) dual license

### Known limitations

- Cloudflare + D1 only for the reference implementation
- No WebAuthn passkeys yet
- No futarchy forecaster, no conviction voting, no auto-merge of code PRs
- Audit chain detects but does not prevent tampering. External daily snapshots help.
