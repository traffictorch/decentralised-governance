# Contributing

Thanks for wanting to help. This repo exists because governance systems should not be black boxes.

## What we welcome most

1. **Ports to other stacks** — Node+Postgres, Supabase, Lambda, Django, Rails, Phoenix.
2. **Governance-theory corrections** — if the block threshold, quorum, or sortition logic has a flaw.
3. **Security reviews** — especially of the audit chain and eligibility rules.
4. **Documentation improvements** — especially porting examples.
5. **Translations** — governance docs are text; they travel well.

## What we do not merge

- Blockchains, tokens, or gas fees.
- Admin override mechanisms. The system has no admin by design.
- Anonymized voting by default. Votes are public and reversible until close.
- Feature creep beyond `docs/api-contract.md` without an issue first.

## Before you open a PR

- Open an issue first for anything non-trivial.
- One concern per PR.
- Test locally: `cd engine/cloudflare && npx wrangler dev` — worker must boot clean.
- Simulator: `node --check` all three files.

## Commit messages

Imperative present, one line: `Add: getMe handler`, `Fix: audit chain verify on empty chain`.

## Code style

- Vanilla JS, ES modules.
- No build step for the simulator or examples.
- 2-space indents (see `.editorconfig`).
- Comment the *why*, not the *what*.

## Questions

Open a discussion, not a DM. Public questions become documentation for the next person.
