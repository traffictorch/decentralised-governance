# Porting Guide

The Cloudflare Worker is one implementation. Any backend that speaks the same HTTP contract works with the same frontend. This guide walks through three concrete ports.

## What stays identical

**The API contract.** All 21 endpoints, same request/response shapes. See `docs/api-contract.md`.

**The database schema.** All 13 tables. SQLite-compatible SQL works with minor tweaks on Postgres/MySQL.

**The audit chain algorithm.** SHA-256 linking, `prev_hash + this_hash`. Byte-for-byte the same.

**The state machine.** `draft -> vote -> passed/rejected`. Same rules, same transitions.

## What changes

**HTTP routing framework.** Express, Fastify, Rails routes, Phoenix routes, Lambda handler — your choice.

**JWT verification.** `jose` in Node, `PyJWT` in Python, `php-jwt` in PHP. Same HMAC-SHA256 verification, different library.

**Database access.** Postgres client, MySQL client, ORM — the query shape is the same, the code differs.

**Crypto.** `crypto.subtle.digest` in Cloudflare workers/web. `crypto.createHash('sha256')` in Node. `hashlib.sha256` in Python. All produce the same bytes.

## Port 1 — Node.js + Postgres (Express)

Rough size: 400 lines of route handlers + 200 lines of helpers. Most of the logic is ID generation and state validation — the actual SQL is short.

### Setup

    npm init -y
    npm install express pg jsonwebtoken dotenv
    psql -U postgres -c "CREATE DATABASE governance;"
    psql -U postgres -d governance -f schema.postgres.sql

### The schema

Postgres needs a few type changes:

    -- SQLite:             -- Postgres:
    INTEGER PRIMARY KEY   -> SERIAL PRIMARY KEY  (or BIGSERIAL)
    TEXT                  -> TEXT  (unchanged)
    TIMESTAMP             -> TIMESTAMPTZ  (or TIMESTAMP)
    REAL                  -> DOUBLE PRECISION
    INTEGER (unix sec)    -> BIGINT  (or INTEGER)

A `schema.postgres.sql` rewrite from `engine/cloudflare/schema.sql` takes 20 minutes.

### The JWT verifier

    const jwt = require('jsonwebtoken');

    function verifyJWT(token, secret) {
      if (!token || typeof token !== 'string') return null;
      try {
        return jwt.verify(token, secret, { algorithms: ['HS256'] });
      } catch {
        return null;
      }
    }

Note: jsonwebtoken checks `exp` automatically; you don't need manual checking.

### The audit chain helper

    const crypto = require('crypto');

    function sha256(str) {
      return crypto.createHash('sha256').update(str).digest('hex');
    }

    async function writeAudit(pgClient, tableName, action, payload) {
      const last = await pgClient.query(
        'SELECT this_hash FROM rt_audit_chain ORDER BY created_at DESC LIMIT 1'
      );
      const prevHash = last.rows[0]?.this_hash || 'GENESIS';
      const payloadStr = JSON.stringify(payload);
      const thisHash = sha256(prevHash + '|' + tableName + '|' + action + '|' + payloadStr);
      const rowId = 'a_' + Date.now() + '_' + crypto.randomBytes(4).toString('hex');
      await pgClient.query(
        `INSERT INTO rt_audit_chain (row_id, table_name, action, payload, prev_hash, this_hash, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [rowId, tableName, action, payloadStr, prevHash, thisHash, Math.floor(Date.now() / 1000)]
      );
      return thisHash;
    }

### The route handlers

    app.get('/api/rt/proposals', async (req, res) => {
      const { rows } = await pool.query(
        'SELECT * FROM rt_proposals ORDER BY created_at DESC LIMIT 50'
      );
      res.set('Cache-Control', 'public, max-age=60');
      res.json({ proposals: rows });
    });

    app.get('/api/rt/proposals/:slug_or_id', async (req, res) => {
      const { slug_or_id } = req.params;
      const { rows } = await pool.query(
        'SELECT * FROM rt_proposals WHERE slug = $1 OR id = $1 LIMIT 1',
        [slug_or_id]
      );
      if (rows.length === 0) return res.status(404).json({ error: 'Not found' });
      const p = rows[0];
      const votes = await pool.query(
        'SELECT choice, COUNT(*) FROM rt_votes WHERE proposal_id = $1 AND choice IS NOT NULL GROUP BY choice',
        [p.id]
      );
      const tally = { yes: 0, no: 0, abstain: 0 };
      votes.rows.forEach(r => { tally[r.choice] = parseInt(r.count); });
      const comments = await pool.query(
        'SELECT * FROM rt_comments WHERE proposal_id = $1 AND deleted_at IS NULL ORDER BY created_at ASC',
        [p.id]
      );
      res.json({ proposal: p, tally, comments: comments.rows });
    });

    app.post('/api/rt/proposals/:slug/vote', async (req, res) => {
      const user = verifyJWT(req.headers.authorization?.replace('Bearer ', ''), process.env.JWT_SECRET);
      if (!user) return res.status(401).json({ error: 'Unauthorized' });
      const { choice } = req.body;
      if (!['yes', 'no', 'abstain'].includes(choice)) {
        return res.status(400).json({ error: 'choice must be yes|no|abstain' });
      }
      const prop = await pool.query(
        'SELECT * FROM rt_proposals WHERE slug = $1', [req.params.slug]
      );
      if (prop.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      if (prop.rows[0].phase !== 'vote') return res.status(400).json({ error: 'Not in vote phase' });

      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(
          `INSERT INTO rt_votes (proposal_id, entity_id, choice, cast_at)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (proposal_id, entity_id) DO UPDATE SET choice = EXCLUDED.choice, cast_at = EXCLUDED.cast_at`,
          [prop.rows[0].id, String(user.id), choice, Math.floor(Date.now() / 1000)]
        );
        await writeAudit(client, 'rt_votes', 'insert', { proposal_id: prop.rows[0].id, entity_id: user.id, choice });
        await client.query('COMMIT');
      } catch (e) {
        await client.query('ROLLBACK');
        return res.status(500).json({ error: e.message });
      } finally {
        client.release();
      }
      res.json({ ok: true, choice });
    });

The pattern for the other 18 endpoints is the same: verify JWT, validate input, one DB transaction, audit entry, respond.

### Considerations

- **`BEGIN`/`COMMIT`** — Postgres has real transactions; use them for every multi-write operation (vote + audit chain, close-vote + resolution + config apply).
- **`ON CONFLICT ... DO UPDATE`** — Postgres idiom for idempotent inserts. Cleaner than SQLite's `INSERT OR REPLACE`.
- **Connection pooling** — `pg.Pool` handles this for you. Don't open a new client per request.

## Port 2 — Supabase

Supabase = Postgres + auto-generated REST + edge functions. You get the database for free; use RLS for row-level security, edge functions for endpoints that need crypto or state-machine logic.

### Schema

Copy `engine/cloudflare/schema.sql` into Supabase SQL editor, adjust types (INTEGER → BIGINT for timestamps, REAL → DOUBLE PRECISION). Enable Row Level Security.

### RLS policies

    -- public read for proposals, comments, resolutions
    ALTER TABLE rt_proposals ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "public read" ON rt_proposals FOR SELECT USING (true);

    -- votes: read by authenticated users, insert only for self
    ALTER TABLE rt_votes ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "public read" ON rt_votes FOR SELECT USING (true);
    CREATE POLICY "own votes" ON rt_votes FOR INSERT WITH CHECK (auth.uid()::text = entity_id);

### Edge functions for the state machine

Endpoints that need atomicity across multiple tables (open-vote, close-vote) belong in an edge function:

    // supabase/functions/close-vote/index.ts
    import { serve } from "https://deno.land/std/http/server.ts";
    import { createClient } from "https://esm.sh/@supabase/supabase-js";

    serve(async (req) => {
      const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_KEY")!);
      const { slug } = await req.json();

      // 1. Load proposal
      // 2. Compute outcome
      // 3. Insert resolution + audit entry in a transaction
      // 4. Update proposal phase

      return new Response(JSON.stringify({ ok: true }));
    });

### Considerations

- **JWT verification is free** — Supabase handles it via `auth.uid()`. You don't need to verify HMAC yourself; use RLS policies instead.
- **Audit chain** — write via a Postgres function, called from the edge function. `pgcrypto` extension has `digest()` for SHA-256.
- **Rate limiting** — Supabase doesn't ship rate limits; use Cloudflare in front or Upstash Redis.

## Port 3 — AWS Lambda + DynamoDB

DynamoDB is a different paradigm (no joins, no SQL). The port is more work but doable.

### Table design

- `rt-proposals` (PK: `id`, SK: none)
- `rt-votes` (PK: `proposal_id`, SK: `entity_id`)
- `rt-comments` (PK: `proposal_id`, SK: `comment_id`)
- `rt-audit-chain` (PK: `row_id`, SK: none)
- `rt-resolutions` (PK: `id`, SK: none)
- `rt-entities` (PK: `entity_id`)
- `rt-config` (PK: `key`)

### Atomicity via `TransactWriteItems`

    const { DynamoDBClient, TransactWriteItemsCommand } = require("@aws-sdk/client-dynamodb");

    async function castVoteAndAudit(proposalId, entityId, choice) {
      const now = Math.floor(Date.now() / 1000);
      const lastHash = await getLastAuditHash();
      const payload = JSON.stringify({ proposal_id: proposalId, entity_id: entityId, choice });
      const thisHash = sha256(lastHash + '|rt_votes|insert|' + payload);

      await ddb.send(new TransactWriteItemsCommand({
        TransactItems: [
          { Put: { TableName: 'rt-votes', Item: { proposal_id: { S: proposalId }, entity_id: { S: entityId }, choice: { S: choice }, cast_at: { N: String(now) } } } },
          { Put: { TableName: 'rt-audit-chain', Item: {
            row_id: { S: 'a_' + now + '_' + Math.random().toString(36).slice(2, 8) },
            prev_hash: { S: lastHash },
            this_hash: { S: thisHash },
            payload: { S: payload },
            created_at: { N: String(now) }
          } } }
        ]
      }));
    }

### Queries

The list endpoint needs `Scan` or a GSI:

    const items = await ddb.send(new ScanCommand({
      TableName: 'rt-proposals',
      IndexName: 'phase-created_at-index',  // GSI, ordered by created_at
      Limit: 50
    }));

Sorting and pagination via `ExclusiveStartKey`. No `ORDER BY` — you build a GSI.

### Considerations

- **Tally computation** is expensive in DynamoDB — no `GROUP BY`. Cache the tally on the proposal row and update it on every vote (same pattern the Cloudflare impl uses).
- **Audit chain is naturally strong in DynamoDB** — no direct UPDATE, so accidental mutation is harder.
- **Cold-start cost** — Node.js Lambda + AWS SDK ~ 400ms. Use provisioned concurrency for the governance API.

## Common porting gotchas

1. **Timestamps.** Always Unix seconds. Never ISO strings. All languages agree.
2. **Boolean to integer.** SQLite stores `1`/`0`. Postgres has real booleans. Convert carefully — `verified_at IS NOT NULL` is safer than `verified_at = true`.
3. **NULL vs empty string.** SQLite and Postgres differ. Prefer NULL for "absent".
4. **AUTOINCREMENT.** SQLite `AUTOINCREMENT` = Postgres `SERIAL` = DynamoDB needs `ulid()` or `uuid()` on insert. Pick one and stick with it.
5. **JWT secret.** Must be the **same** across your auth worker and governance worker. Rotate together.

## Not supported ports

- **Firebase Realtime DB / Firestore** — document-based, no transactions across collections at the scale you need. Supabase is the equivalent.
- **Redis as primary store** — no durable guarantees. Use as cache only.
- **Anything without SQL-like transactions** — the audit chain requires atomic multi-write.

## Contribute a port

Porting guide entries welcome. Open a PR with `docs/ports/<stack>.md` containing:

1. The schema rewrite
2. The JWT verifier snippet
3. The audit chain helper
4. Three worked endpoints (list, cast vote, close vote)
5. Gotchas specific to your stack
