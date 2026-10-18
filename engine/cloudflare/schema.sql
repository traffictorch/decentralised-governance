-- ==========================================================================
-- Decentralised Governance — D1 schema (v1)
-- Merge of all historical migrations. Fresh installs need ONLY this file.
-- Run:  wrangler d1 execute <DB_NAME> --remote --file=schema.sql
-- ==========================================================================

-- Entities: one row per eligible participant.
CREATE TABLE IF NOT EXISTS rt_entities (
  entity_id           TEXT PRIMARY KEY,
  eligible_since      INTEGER NOT NULL,
  passkey_registered  INTEGER NOT NULL DEFAULT 0,
  status              TEXT NOT NULL DEFAULT 'active'    -- active | pending | suspended | retired
);

-- Proposals: the full lifecycle. All columns present from day 1 — no ALTERs.
CREATE TABLE IF NOT EXISTS rt_proposals (
  id                        TEXT PRIMARY KEY,
  author_entity_id          TEXT NOT NULL,
  slug                      TEXT UNIQUE NOT NULL,
  title                     TEXT NOT NULL,
  body_md                   TEXT NOT NULL,
  kind                      TEXT NOT NULL,              -- advisory | config | meta | code
  category                  TEXT NOT NULL,              -- feature | policy | meta | security
  phase                     TEXT NOT NULL DEFAULT 'draft', -- draft | vote | passed | rejected | withdrawn
  created_at                INTEGER NOT NULL,
  vote_starts_at            INTEGER,
  vote_ends_at              INTEGER,
  quorum_pct                REAL NOT NULL DEFAULT 0.20,
  threshold_pct             REAL NOT NULL DEFAULT 0.66,
  block_pct                 REAL NOT NULL DEFAULT 0.25,
  eligible_count            INTEGER,
  resolution_id             TEXT,
  tally_yes                 INTEGER NOT NULL DEFAULT 0,
  tally_no                  INTEGER NOT NULL DEFAULT 0,
  tally_abstain             INTEGER NOT NULL DEFAULT 0,
  reconsider_of_proposal_id TEXT,                       -- set on reconsider proposals
  linked_pr_url             TEXT                        -- for code proposals
);

-- Votes: one row per (proposal, entity). Changeable until close.
CREATE TABLE IF NOT EXISTS rt_votes (
  proposal_id  TEXT NOT NULL,
  entity_id    TEXT NOT NULL,
  choice       TEXT,                                    -- yes | no | abstain | NULL (unrevealed commit)
  commitment   TEXT,                                    -- reserved for future commit-reveal
  cast_at      INTEGER NOT NULL,
  PRIMARY KEY (proposal_id, entity_id)
);

-- Comments: one level of threading via parent_id.
CREATE TABLE IF NOT EXISTS rt_comments (
  id          TEXT PRIMARY KEY,
  proposal_id TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  parent_id   TEXT,
  body_md     TEXT NOT NULL,
  created_at  INTEGER NOT NULL,
  deleted_at  INTEGER
);

-- Objections: filed by Objector's Bench members. Pauses a vote for 72h.
CREATE TABLE IF NOT EXISTS rt_objections (
  id           TEXT PRIMARY KEY,
  proposal_id  TEXT NOT NULL,
  bench_entity TEXT NOT NULL,
  reason_md    TEXT NOT NULL,
  created_at   INTEGER NOT NULL,
  expires_at   INTEGER NOT NULL
);

-- Resolutions: one row per closed vote. Hash-chained.
CREATE TABLE IF NOT EXISTS rt_resolutions (
  id                         TEXT PRIMARY KEY,
  proposal_id                TEXT NOT NULL UNIQUE,
  outcome                    TEXT NOT NULL,             -- passed | rejected | no_quorum
  tally_json                 TEXT NOT NULL,
  prev_hash                  TEXT,
  this_hash                  TEXT NOT NULL,
  votes_hash                 TEXT,                       -- SHA-256 of exact vote set at close
  reversed_at                INTEGER,
  reversed_by_resolution_id  TEXT,
  created_at                 INTEGER NOT NULL
);

-- Audit chain: every write appends here. Tamper-evident.
CREATE TABLE IF NOT EXISTS rt_audit_chain (
  row_id      TEXT PRIMARY KEY,
  table_name  TEXT NOT NULL,
  action      TEXT NOT NULL,                            -- insert | update | delete
  payload     TEXT NOT NULL,
  prev_hash   TEXT,
  this_hash   TEXT NOT NULL,
  created_at  INTEGER NOT NULL
);

-- Audit checkpoints: signed snapshots every N rows for fast verification.
CREATE TABLE IF NOT EXISTS rt_audit_checkpoints (
  id           TEXT PRIMARY KEY,
  last_row_id  TEXT NOT NULL,
  last_hash    TEXT NOT NULL,
  created_at   INTEGER NOT NULL
);

-- Bench: sortition-selected members with fixed terms.
CREATE TABLE IF NOT EXISTS rt_bench (
  id              TEXT PRIMARY KEY,
  entity_id       TEXT NOT NULL,
  term_starts_at  INTEGER NOT NULL,
  term_ends_at    INTEGER NOT NULL,
  active          INTEGER NOT NULL DEFAULT 1
);

-- Reconsiders: link original resolution to its reconsider proposal.
CREATE TABLE IF NOT EXISTS rt_reconsiders (
  id                     TEXT PRIMARY KEY,
  original_resolution_id TEXT NOT NULL,
  reconsider_proposal_id TEXT NOT NULL,
  triggered_at           INTEGER NOT NULL
);

-- Signatures: track who signed a reconsider request.
CREATE TABLE IF NOT EXISTS rt_reconsider_signatures (
  original_resolution_id TEXT NOT NULL,
  entity_id              TEXT NOT NULL,
  signed_at              INTEGER NOT NULL,
  PRIMARY KEY (original_resolution_id, entity_id)
);

-- Config store: self-amending thresholds and flags.
CREATE TABLE IF NOT EXISTS rt_config (
  key                  TEXT PRIMARY KEY,
  value                TEXT NOT NULL,
  set_by_resolution_id TEXT,
  set_at               INTEGER NOT NULL
);

-- Executions: every applied resolution (config + code).
CREATE TABLE IF NOT EXISTS rt_executions (
  id            TEXT PRIMARY KEY,
  resolution_id TEXT NOT NULL,
  target        TEXT NOT NULL,                          -- config | github | advisory
  status        TEXT NOT NULL,                          -- succeeded | skipped | pending_merge | awaiting_pr | pending_delay | failed
  external_ref  TEXT,
  payload       TEXT,
  created_at    INTEGER NOT NULL,
  completed_at  INTEGER
);

-- === INDEXES ===
CREATE INDEX IF NOT EXISTS idx_rt_proposals_phase ON rt_proposals(phase);
CREATE INDEX IF NOT EXISTS idx_rt_votes_proposal  ON rt_votes(proposal_id);
CREATE INDEX IF NOT EXISTS idx_rt_comments_prop   ON rt_comments(proposal_id, created_at);
CREATE INDEX IF NOT EXISTS idx_rt_bench_active    ON rt_bench(active, term_ends_at);
CREATE INDEX IF NOT EXISTS idx_rt_reconsiders_res ON rt_reconsiders(original_resolution_id);
CREATE INDEX IF NOT EXISTS idx_rt_exec_res        ON rt_executions(resolution_id);

-- === SEED: default config values ===
INSERT OR IGNORE INTO rt_config (key, value, set_at) VALUES
  ('default_quorum_pct',       '0.20', strftime('%s','now')),
  ('default_threshold_pct',    '0.66', strftime('%s','now')),
  ('default_block_pct',        '0.25', strftime('%s','now')),
  ('default_threshold_pct_meta', '0.75', strftime('%s','now'));
