# Decentralised Governance

**An open-source governance engine — proposals, discussion, consensus voting, tamper-evident audit chain. Zero admin. Zero override. Self-amending.**

[![License: MIT](https://img.shields.io/badge/code-MIT-blue.svg)](LICENSE)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/docs-CC%20BY--SA%204.0-lightgrey.svg)](LICENSE-docs)

## What this is

A working, deployable governance system you can fork and run in an afternoon. Not a spec. Not a whitepaper. Working code, working UI, working simulator — all in one repo.

Built and battle-tested in production at traffictorch.net/community/round-table/, now extracted for anyone to adopt.

## The five guarantees

- **Equal authority** — no admin table exists, by design. Every entity has exactly one voice.
- **Tamper-evident** — every vote, comment, and resolution is SHA-256 chained with the previous.
- **Minority protected** — 25% NO blocks any proposal, even at 66% YES.
- **Reversible** — 10% of entities can reopen any decision within 30 days.
- **Self-amending** — the rules that govern the system are themselves amendable by the same vote.

## Install in 2 minutes

    git clone https://github.com/[YOUR_USERNAME]/decentralised-governance
    cd decentralised-governance/engine/cloudflare
    cp wrangler.toml.example wrangler.toml
    # edit wrangler.toml: set database_name + database_id
    npx wrangler d1 create decentralised-governance
    npx wrangler d1 execute decentralised-governance --remote --file=schema.sql
    npx wrangler d1 execute decentralised-governance --remote --file=seed-proposals.sql
    npx wrangler secret put JWT_SECRET     # paste your auth secret
    npx wrangler deploy

Your governance API is live at `https://decentralised-governance.<your-subdomain>.workers.dev`.

## See it live

The full system runs at **traffictorch.net/community/round-table/** — proposal list, live voting, threaded comments, Objector Bench, audit chain, 5-scenario simulator.

## What is in the repo

    engine/
      cloudflare/    Deployable Cloudflare Worker + D1 schema (reference impl)
      simulator/     Vanilla JS, zero deps — drops into any site
      docs/          Governance text as editable markdown templates
    examples/
      standalone/    Full working demo (mock data, no backend needed)
      with-tailwind/ Traffic Torch aesthetic
      with-plain-css/Minimal aesthetic
    docs/
      api-contract.md   THE contract — port to any stack
      architecture.md
      security-model.md
      audit-chain.md
      porting-guide.md  Node+Postgres, Supabase, Lambda+DynamoDB
      governance-101.md
      faq.md

## Port to your stack

The **API contract** in `docs/api-contract.md` is framework-agnostic. Ship the Cloudflare reference as-is, or implement the endpoints in Node.js + Postgres, Supabase, AWS Lambda + DynamoDB, or anywhere that can run HTTP + a database. Worked examples in `docs/porting-guide.md`.

## The simulator

`engine/simulator/` — 3 files, zero dependencies:

    <div id="sim"></div>
    <link rel="stylesheet" href="engine/simulator/governance-simulator.css">
    <script src="engine/simulator/governance-scenarios.js"></script>
    <script src="engine/simulator/governance-simulator.js"></script>
    <script>
      GovernanceSimulator.init(document.getElementById('sim'), {
        brand: 'Your Project',
        brandColor: '#6366f1',
        autoplay: true
      });
    </script>

5 built-in scenarios, all editable in `governance-scenarios.js`.

## Why you would want this

If you have a community that wants a real say in how decisions are made — beyond polls and Discord votes — this is the whole stack. Config changes apply immediately. Rule changes require a supermajority. Contentious decisions can be paused by an Objector Bench. Every choice is permanent, verifiable, and reversible within 30 days.

It is designed for projects where "we voted on it" needs to mean something.

## What this is not

- Not a token. No blockchain. No gas fees. No speculation.
- Not anonymous. Votes are public by design — auditability over anonymity.
- Not leaderless. Someone still deploys code. But that person has no vote-weight advantage.
- Not magical. Sybil resistance depends on your auth. Trust assumptions documented in `docs/security-model.md`.

## License

- **Code** (`engine/`, `examples/`, `scripts/`, `.github/`) → MIT
- **Docs** (`docs/`, `engine/docs/`) → CC BY-SA 4.0

Dual license by design: code should be unencumbered; governance text should stay in the commons.

## Contributing

See `CONTRIBUTING.md`. Issues and PRs welcome — especially port requests for non-Cloudflare stacks.

## Origin

Built by Traffic Torch (traffictorch.net) as the governance layer for its community tools. Open-sourced because a governance system that cannot be forked is a trap.
