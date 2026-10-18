---
name: Port Request
about: Request a port to another stack (Node, Rails, Django, Lambda, Supabase, etc.)
title: '[PORT] '
labels: port, help wanted
---

## Target stack
<!-- e.g. Node.js + Postgres, Rails + MySQL, Django, Lambda + DynamoDB -->

## Who you are
- [ ] I want to use this stack and could contribute the port
- [ ] I want to use this stack but can't contribute the port myself
- [ ] I'm just curious if it's possible

## Which parts matter most
The API contract (docs/api-contract.md) is the only contract that must be preserved.
- [ ] JWT verification with shared secret
- [ ] Audit chain SHA-256
- [ ] State machine (draft/vote/resolved)
- [ ] All 21 endpoints
- [ ] D1 schema adjustments for target DB
- [ ] Rate limiting
- [ ] pending_delay config execution (72h meta delay)
