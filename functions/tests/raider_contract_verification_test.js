'use strict';
const assert = require('node:assert/strict');
const { createContractVerification, hasVideoTrack } = require('../raider_contract_verification');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
function atom(type, body) { const h = Buffer.alloc(8); h.writeUInt32BE(body.length + 8); h.write(type, 4); return Buffer.concat([h, body]); }
function media(handler = 'vide') {
  const h = Buffer.alloc(12); h.write(handler, 8);
  return Buffer.concat([atom('ftyp', Buffer.from('isom0000')), atom('moov', atom('trak', atom('mdia', atom('hdlr', h))))]);
}
function harness() {
  const store = new Map([['arc_raider_contracts/c', { status: 'inProgress', hunterUid: 'hunter', reporterUid: 'issuer', targetUid: 'target' }], ['users/hunter', { countryCode: 'GB' }]]);
  const snap = path => ({ exists: store.has(path), data: () => structuredClone(store.get(path)) });
  const ref = path => ({ path, get: async () => snap(path), collection: name => ({ doc: id => ref(`${path}/${name}/${id}`) }) });
  let queue = Promise.resolve();
  const db = { collection: name => ({ doc: id => ref(`${name}/${id}`) }), runTransaction: fn => {
    const pending = queue.then(async () => {
      const writes = [];
      const result = await fn({ get: async r => snap(r.path), update: (r, value) => writes.push([r.path, { ...store.get(r.path), ...value }]),
        create: (r, value) => { assert(!store.has(r.path), 'duplicate create'); writes.push([r.path, value]); } });
      for (const [path, value] of writes) store.set(path, value);
      return result;
    }); queue = pending.catch(() => {}); return pending;
  } };
  const state = { bytes: media(), generation: '1' };
  const bucket = { file: () => ({ getMetadata: async () => [{ contentType: 'video/mp4', size: state.bytes.length, generation: state.generation }], download: async () => [state.bytes] }) };
  return { store, state, api: createContractVerification({ db, bucket, timestamp: () => 'SERVER', HttpsError, now: () => new Date('2026-09-14T12:00:00Z') }) };
}
const request = (uid, data) => ({ auth: { uid }, data: { contractId: 'c', submissionId: 's1', ...data } });
const upload = { storagePath: 'contract_evidence/c/hunter/s1.mp4' };
async function denied(promise, code) { await assert.rejects(promise, error => error.code === code); }
async function run() {
  assert(hasVideoTrack(media())); assert(!hasVideoTrack(media('soun'))); assert(!hasVideoTrack(Buffer.from('ftypvide')));
  const h = harness();
  h.store.get('arc_raider_contracts/c').status = 'accepted';
  await denied(h.api.submit(request('hunter', upload)), 'failed-precondition');
  assert(!h.store.has('raider_verified_results/c'));
  h.store.get('arc_raider_contracts/c').status = 'inProgress';
  await denied(h.api.review(request('issuer', { decision: 'confirm' })), 'failed-precondition');
  await denied(h.api.submit(request('other', upload)), 'permission-denied');
  await denied(h.api.submit(request('hunter', { storagePath: 'contract_evidence/other/hunter/s1.mp4' })), 'invalid-argument');
  h.state.bytes = media('soun'); await denied(h.api.submit(request('hunter', upload)), 'failed-precondition'); h.state.bytes = media();
  await h.api.submit(request('hunter', upload));
  assert.equal(h.store.get('arc_raider_contracts/c').verificationStatus, 'pending');
  assert(!h.store.has('raider_verified_results/c'));
  await denied(h.api.review(request('hunter', { decision: 'confirm' })), 'permission-denied');
  await denied(h.api.review(request('other', { decision: 'confirm' })), 'permission-denied');
  await denied(h.api.review(request('issuer', { decision: 'confirm', submissionId: 'stale' })), 'failed-precondition');
  await h.api.review(request('issuer', { decision: 'reject', reason: 'Target not visible' }));
  assert(!h.store.has('raider_verified_results/c'));
  await denied(h.api.review(request('issuer', { decision: 'confirm' })), 'failed-precondition');
  await h.api.submit(request('hunter', { submissionId: 's2', storagePath: 'contract_evidence/c/hunter/s2.mp4' }));
  const confirmation = request('issuer', { submissionId: 's2', decision: 'confirm' });
  await Promise.all([h.api.review(confirmation), h.api.review(confirmation)]);
  assert.equal(h.store.get('arc_raider_contracts/c').status, 'completed');
  assert.equal(h.store.get('arc_raider_contracts/c').verifiedByUid, 'issuer');
  const result = h.store.get('raider_verified_results/c');
  assert.equal(result.countryCode, 'GB'); assert.equal(result.month, '2026-09'); assert.equal(result.verificationStatus, 'verified');
  assert.equal([...h.store.keys()].filter(x => x.startsWith('raider_verified_results/')).length, 1);
  await denied(h.api.submit(request('hunter', { submissionId: 's3', storagePath: 'contract_evidence/c/hunter/s3.mp4' })), 'failed-precondition');
  assert.equal(h.store.get('users/hunter').raiderContractStats, undefined);
  const missing = harness(); await missing.api.submit(request('hunter', upload)); missing.store.get('arc_raider_contracts/c').evidence = [];
  await denied(missing.api.review(request('issuer', { decision: 'confirm' })), 'failed-precondition');
  const changed = harness(); await changed.api.submit(request('hunter', upload)); changed.state.generation = '2';
  await denied(changed.api.review(request('issuer', { decision: 'confirm' })), 'failed-precondition');
  const invalidCountry = harness(); invalidCountry.store.set('users/hunter', { countryCode: 'ZZ' });
  await invalidCountry.api.submit(request('hunter', upload));
  await invalidCountry.api.review(request('issuer', { decision: 'confirm' }));
  assert.equal(invalidCountry.store.get('raider_verified_results/c').countryCode, '');
  const self = harness(); self.store.get('arc_raider_contracts/c').reporterUid = 'hunter';
  await denied(self.api.submit(request('hunter', upload)), 'permission-denied');
  const expired = harness(); expired.store.get('arc_raider_contracts/c').expiresAt = new Date('2026-09-01');
  await denied(expired.api.submit(request('hunter', upload)), 'failed-precondition');
  const lateReview = harness(); await lateReview.api.submit(request('hunter', upload));
  lateReview.store.get('arc_raider_contracts/c').expiresAt = new Date('2026-09-01');
  await denied(lateReview.api.review(request('issuer', { decision: 'confirm' })), 'failed-precondition');
  console.log('Hunter contract transactional authority: PASS (including expiry submission/review)');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
