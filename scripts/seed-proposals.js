#!/usr/bin/env node
// seed-proposals.js — POST the 7 founding proposals to a live governance API.
// Usage: node scripts/seed-proposals.js <BASE_URL> <BEARER_JWT>

var argv = process.argv;
var BASE_URL = argv[2];
var TOKEN = argv[3];

if (!BASE_URL || !TOKEN) {
  console.error('Usage: node scripts/seed-proposals.js <BASE_URL> <BEARER_JWT>');
  console.error('Example: node scripts/seed-proposals.js https://gov.example.com eyJhbGci...');
  process.exit(1);
}

var PROPOSALS = [
  { title: 'Ratify the Constitution', body_md: 'The complete ruleset. Equal authority. No admin. Tamper-evident. Reversible.', kind: 'meta', category: 'meta' },
  { title: 'Define "Entity"', body_md: 'Account age >= 7 days, prior activity, human-operated. Bots not entities unless Meta-authorized.', kind: 'meta', category: 'meta' },
  { title: 'Set Default Thresholds', body_md: 'Quorum 20%. Pass 66% (75% Meta). Block 25% NO. Effective pass bar is 75% YES.', kind: 'meta', category: 'meta' },
  { title: 'Establish the Objector Bench', body_md: '5 members, 30-day sortition, 72h pause. Cannot block, only slow.', kind: 'meta', category: 'meta' },
  { title: 'Define the Execution Bridge', body_md: 'Config immediate. Meta +72h delay. Code requires linked PR.', kind: 'meta', category: 'meta' },
  { title: 'The Reconsider Window', body_md: '10% of eligible entities can reopen any resolution within 30 days.', kind: 'meta', category: 'meta' },
  { title: 'First Feature Proposal (open)', body_md: 'Reserved for the community first real decision.', kind: 'advisory', category: 'feature' }
];

async function main() {
  var ok = 0;
  var failed = 0;
  for (var i = 0; i < PROPOSALS.length; i++) {
    var p = PROPOSALS[i];
    process.stdout.write('POST ' + p.title.slice(0, 40) + '... ');
    try {
      var res = await fetch(BASE_URL + '/api/rt/proposals', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + TOKEN
        },
        body: JSON.stringify(p)
      });
      var data = await res.json().catch(function () { return {}; });
      if (!res.ok) {
        console.log('FAIL HTTP ' + res.status + ' ' + (data.error || ''));
        failed++;
      } else {
        console.log('OK ' + data.slug);
        ok++;
      }
    } catch (e) {
      console.log('FAIL ' + e.message);
      failed++;
    }
    await new Promise(function (r) { setTimeout(r, 500); });
  }
  console.log('');
  console.log('Done: ' + ok + ' created, ' + failed + ' failed');
  if (failed > 0) process.exit(1);
}

main();
