-- Seeds the 7 founding proposals. Run AFTER schema.sql.
-- Idempotent: INSERT OR IGNORE, safe to re-run.
INSERT OR IGNORE INTO rt_proposals
  (id, author_entity_id, slug, title, body_md, kind, category, phase, created_at)
VALUES
  ('rt0000','system','ratify-constitution','Ratify the Round Table Constitution',
   'The complete ruleset. Equal authority. No admin. Tamper-evident. Reversible.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0001','system','define-entity','Define "Entity"',
   'Account age >= 7 days, prior community activity, human-operated. Bots not entities unless Meta-authorized.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0002','system','default-thresholds','Set Default Thresholds',
   'Quorum 20%. Pass 66% (75% Meta). Block 25% NO. Effective pass bar is 75% YES.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0003','system','objectors-bench','Establish the Objector Bench',
   '5 members, 30-day sortition, 72h pause. Cannot block, only slow.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0004','system','execution-bridge','Define the Execution Bridge',
   'Config immediate. Meta +72h delay. Code requires linked PR.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0005','system','reconsider-window','The Reconsider Window',
   '10% of eligible entities can reopen any resolution within 30 days.',
   'meta','meta','draft',strftime('%s','now')),
  ('rt0006','system','first-feature','First Feature Proposal (open)',
   'Reserved for the community first real decision.',
   'advisory','feature','draft',strftime('%s','now'));
