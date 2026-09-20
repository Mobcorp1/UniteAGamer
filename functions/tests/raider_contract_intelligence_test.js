'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { createRaiderContractIntelligence, deriveIntelligence, hunterProjection, targetProjection, effectiveStatus } = require('../raider_contract_intelligence');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
const NOW = new Date('2026-09-20T12:00:00Z');
function atom(type, body) { const h = Buffer.alloc(8); h.writeUInt32BE(body.length + 8); h.write(type, 4); return Buffer.concat([h, body]); }
const handler = Buffer.alloc(12); handler.write('vide', 8);
const video = Buffer.concat([atom('ftyp', Buffer.from('isom0000')), atom('moov', atom('trak', atom('mdia', atom('hdlr', handler))))]);
function harness() {
  const store = new Map();
  for (const uid of ['issuer', 'target', 'hunter', 'mod', 'other']) store.set(`users/${uid}`, { ageVerification: { verifiedOver18: true }, ...(uid === 'mod' ? { isModerator: true } : {}) });
  store.set('trading_sessions/s', { traderOneUid: 'issuer', traderTwoUid: 'target', traderTwoName: 'Target Name', status: 'ready' });
  const snap = path => ({ id: path.split('/').pop(), ref: ref(path), exists: store.has(path), data: () => structuredClone(store.get(path)) });
  const ref = path => ({ path, get: async () => snap(path), collection: name => collection(`${path}/${name}`) });
  function collection(path, filters = []) { return { doc: id => ref(`${path}/${id}`),
    where: (field, op, value) => collection(path, [...filters, [field, op, value]]),
    get: async () => ({ docs: [...store.keys()].filter(k => k.startsWith(path + '/') && k.split('/').length === path.split('/').length + 1)
      .filter(k => filters.every(([f, op, v]) => op === '==' ? store.get(k)[f] === v : store.get(k)[f] <= v)).map(snap) }) }; }
  let queue = Promise.resolve();
  const db = { collection, runTransaction: fn => {
    const pending = queue.then(async () => {
      const writes = []; let writing = false;
      const result = await fn({ get: async r => { assert(!writing, 'read after write'); return snap(r.path); },
        set: (r, value) => { writing = true; writes.push([r.path, value]); },
        update: (r, value) => { writing = true; assert(store.has(r.path), `missing update ${r.path}`); writes.push([r.path, { ...store.get(r.path), ...value }]); },
        create: (r, value) => { writing = true; assert(!store.has(r.path)); writes.push([r.path, value]); } });
      for (const [p, v] of writes) store.set(p, structuredClone(v));
      return result;
    }); queue = pending.catch(() => {}); return pending;
  } };
  const state = { bytes: video, disabled: new Set(), now: NOW };
  const api = createRaiderContractIntelligence({ db, HttpsError, timestamp: () => state.now, now: () => state.now,
    getAuthUser: async uid => ({ disabled: state.disabled.has(uid) }),
    bucket: { file: () => ({ getMetadata: async () => [{ contentType: 'video/mp4', generation: '1', size: state.bytes.length }], download: async () => [state.bytes] }) } });
  return { store, api, state };
}
const req = (uid, data = {}) => ({ auth: { uid }, data });
const denied = (promise, code) => assert.rejects(promise, e => e.code === code);
async function pending(h) { return h.api.recordBetrayal(req('issuer', { sessionId: 's' })); }
async function active(h) {
  const ids = await pending(h);
  await h.api.attachEvidence(req('issuer', { reportId: ids.reportId, storagePath: `conduct_evidence/${ids.reportId}/issuer/clip.mp4` }));
  await h.api.moderateReport(req('mod', { reportId: ids.reportId, approve: true, notes: 'Verified canonical account and betrayal in clip.' }));
  return ids;
}
test('unverified betrayal atomically creates private pending case; concurrent retries are idempotent', async () => {
  const h = harness(); const [a, b] = await Promise.all([pending(h), pending(h)]);
  assert.deepEqual(a, b);
  assert.equal(h.store.get(`arc_raider_contracts/${a.contractId}`).status, 'pending');
  assert.equal(h.store.get('trading_sessions/s').traderOneMarkedBetrayal, true);
  assert.equal([...h.store.keys()].filter(k => /^arc_raider_contracts\/[^/]+$/.test(k)).length, 1);
  assert.deepEqual((await h.api.discover(req('hunter'))).contracts, []);
  await denied(h.api.recordBetrayal(req('other', { sessionId: 's' })), 'permission-denied');
});
test('independent moderator and real report-owned video required before activation', async () => {
  const h = harness(); const ids = await pending(h);
  await denied(h.api.moderateReport(req('mod', { reportId: ids.reportId, approve: true, notes: 'checked' })), 'invalid-argument');
  await denied(h.api.attachEvidence(req('target', { reportId: ids.reportId, storagePath: 'other' })), 'permission-denied');
  h.state.bytes = Buffer.from('not a video');
  await denied(h.api.attachEvidence(req('issuer', { reportId: ids.reportId, storagePath: `conduct_evidence/${ids.reportId}/issuer/clip.mp4` })), 'failed-precondition');
  h.state.bytes = video;
  await active(h);
  assert.equal(h.store.get(`arc_raider_contracts/${ids.contractId}`).status, 'available');
  assert.equal(h.store.get(`arc_raider_reports/${ids.reportId}`).incidentVerification, 'verified');
  await h.api.moderateReport(req('mod', { reportId: ids.reportId, approve: true, notes: 'retry' }));
  assert.equal([...h.store.keys()].filter(k => k.endsWith('/incident_verified')).length, 1);
  h.store.get('users/issuer').isModerator = true;
  await denied(h.api.moderateReport(req('issuer', { reportId: ids.reportId, approve: true, notes: 'self review' })), 'permission-denied');
});
test('canonical target exclusion precedes display name, case, alias and profile UID search', async () => {
  const h = harness(); const ids = await active(h);
  h.store.get(`arc_raider_contracts/${ids.contractId}`).targetGameIdentity = 'Alias#123';
  for (const search of ['', 'Target Name', 'tArGeT nAmE', 'Alias#123', 'target']) {
    assert.equal((await h.api.discover(req('target', { search }))).contracts.length, 0, search);
    assert.equal((await h.api.discover(req('hunter', { search }))).contracts.length, 1, search);
  }
  await denied(h.api.accept(req('target', { contractId: ids.contractId })), 'permission-denied');
  await h.api.accept(req('hunter', { contractId: ids.contractId }));
  assert.equal(h.store.get(`arc_raider_contracts/${ids.contractId}`).hunterUid, 'hunter');
});
test('hunter allowlist cannot leak reporter, identifiers, evidence, timestamps or internal buckets', () => {
  const projection = hunterProjection('c', { targetUid: 'private', reporterUid: 'reporter', hunterUid: 'hunter', evidence: ['private'], sourceSessionId: 's', targetDisplayName: 'Name' },
    deriveIntelligence([], NOW), 'Europe');
  assert.deepEqual(Object.keys(projection).sort(), ['id','targetDisplayName','category','status','evidenceState','rewardSummary','mapAffinity','confidence','activityLikelihood','regionMatch'].sort());
  assert(!JSON.stringify(projection).includes('private'));
});
test('target account projection contains no operational intelligence and no payment requirement', async () => {
  const h = harness(); const ids = await active(h);
  h.store.get(`arc_raider_contracts/${ids.contractId}`).hunterUid = 'secret-hunter';
  h.state.disabled.add('target');
  const [c] = (await h.api.accountStatus(req('target'))).cases;
  assert.deepEqual(Object.keys(c).sort(), ['id','category','status','evidenceState','challengeStatus','canChallenge'].sort());
  assert.equal(c.canChallenge, true);
  assert(!JSON.stringify(c).includes('secret'));
});
test('rolling coarse aggregation requires independent fresh verified incidents; stale and sparse are unknown', () => {
  const report = { status: 'approved', incidentVerification: 'verified', reporterUid: 'a', incidentAt: new Date('2026-09-19T20:13:00Z'), mapId: 'blue_gate', serverRegion: 'Europe' };
  const rows = [report, { ...report, reporterUid: 'b' }, { ...report, reporterUid: 'c' }];
  const intel = deriveIntelligence(rows, NOW);
  assert.equal(intel.mapAffinity, 'blue_gate'); assert.equal(intel.regionAffinity, 'Europe');
  assert.equal(intel.activityHourBuckets[3], 3); assert.equal(intel.confidence, 'MEDIUM');
  assert.equal(intel.recentActivityConfidence, 'UNKNOWN');
  assert.equal(deriveIntelligence([report], NOW).mapAffinity, 'UNKNOWN');
  assert.equal(deriveIntelligence([report, report, report], NOW).confidence, 'LOW');
  assert.equal(deriveIntelligence(rows, new Date('2026-10-01')).confidence, 'LOW');
  assert.equal(deriveIntelligence(rows, new Date('2026-11-01')).verifiedIncidentCount, 0);
  assert.equal(deriveIntelligence(rows.map(r => ({ ...r, status: 'overturned' })), NOW).verifiedIncidentCount, 0);
  assert.equal(deriveIntelligence(rows.map(r => ({ ...r, incidentAt: new Date('2027-01-01') })), NOW).verifiedIncidentCount, 0);
});
test('blocks in either direction, suspension and reporting/hunting restrictions prevent access', async () => {
  const h = harness(); const ids = await active(h);
  for (const block of ['hunter_target', 'target_hunter', 'issuer_hunter']) {
    h.store.set(`uag_user_blocks/${block}`, {});
    assert.equal((await h.api.discover(req('hunter'))).contracts.length, 0);
    await denied(h.api.accept(req('hunter', { contractId: ids.contractId })), 'permission-denied');
    h.store.delete(`uag_user_blocks/${block}`);
  }
  h.state.disabled.add('hunter'); await denied(h.api.discover(req('hunter')), 'permission-denied');
  h.state.disabled.clear(); h.store.set('arc_contract_restrictions/hunter', { huntingRestricted: true });
  await denied(h.api.discover(req('hunter')), 'permission-denied');
  h.store.set('arc_contract_restrictions/issuer', { reportingRestricted: true });
  await denied(pending(h), 'permission-denied');
});
test('expiry is enforced before scheduled sweep and persisted with audit; completed remains resolved', async () => {
  const h = harness(); const ids = await active(h);
  h.state.now = new Date('2026-10-20');
  assert.equal((await h.api.discover(req('hunter'))).contracts.length, 0);
  await denied(h.api.accept(req('hunter', { contractId: ids.contractId })), 'permission-denied');
  assert.equal((await h.api.accountStatus(req('target'))).cases[0].status, 'expired');
  await h.api.expireContracts();
  assert.equal(h.store.get(`arc_raider_contracts/${ids.contractId}`).status, 'expired');
  assert.equal(effectiveStatus({ status: 'completed', expiresAt: NOW }, h.state.now), 'completed');
});
test('target challenge is idempotent, privately reviewed, overturn invalidates derived and verified result history', async () => {
  const h = harness(); const ids = await active(h);
  const payload = { contractId: ids.contractId, reason: 'This incident identifies a different account.' };
  await denied(h.api.challenge(req('other', payload)), 'permission-denied');
  await Promise.all([h.api.challenge(req('target', payload)), h.api.challenge(req('target', payload))]);
  h.store.set(`raider_verified_results/${ids.contractId}`, { verificationStatus: 'verified' });
  await h.api.reviewChallenge(req('mod', { contractId: ids.contractId, overturn: true, notes: 'Identity mismatch verified.' }));
  assert.equal(h.store.get(`arc_raider_contracts/${ids.contractId}`).status, 'overturned');
  assert.equal(h.store.get(`arc_raider_reports/${ids.reportId}`).status, 'overturned');
  assert.equal(h.store.get(`raider_verified_results/${ids.contractId}`).verificationStatus, 'overturned');
  assert.equal((await h.api.accountStatus(req('target'))).cases[0].canChallenge, false);
  assert.equal((await h.api.discover(req('hunter'))).contracts.length, 0);
});
test('withdrawn allegation cancels pending Contract without penalties', async () => {
  const h = harness(); const ids = await pending(h);
  await h.api.reportWithdrawn({ data: { after: { data: () => ({ status: 'withdrawn', contractId: ids.contractId, reporterUid: 'issuer' }) } } });
  assert.equal(h.store.get(`arc_raider_contracts/${ids.contractId}`).status, 'cancelled');
  assert.equal(h.store.get('users/target').reputationScore, undefined);
});
test('manual reports cannot activate without canonical identity binding', async () => {
  const h = harness();
  h.store.set('arc_raider_reports/manual', { status: 'submitted', reporterUid: 'issuer', targetUid: '', targetDisplayName: 'Target', requestContract: true,
    evidence: [{ storagePath: 'conduct_evidence/manual/issuer/clip.mp4' }] });
  await denied(h.api.moderateReport(req('mod', { reportId: 'manual', approve: true, notes: 'checked' })), 'invalid-argument');
  const result = await h.api.moderateReport(req('mod', { reportId: 'manual', approve: true, targetUid: 'target', notes: 'Account match verified.' }));
  assert.equal(h.store.get(`arc_raider_contracts/${result.contractId}`).targetUid, 'target');
});
test('duplicate verified clip cannot activate a second report; duplicate clip does not inflate confidence', async () => {
  const h = harness(); const ids = await active(h);
  const original = h.store.get(`arc_raider_reports/${ids.reportId}`);
  h.store.set('arc_raider_reports/duplicate', { ...original, id: 'duplicate', contractId: '', status: 'submitted',
    evidence: [{ storagePath: 'conduct_evidence/duplicate/issuer/copy.mp4' }] });
  await denied(h.api.moderateReport(req('mod', { reportId: 'duplicate', approve: true, notes: 'Repeated clip' })), 'already-exists');
  const rows = ['a','b','c'].map(reporterUid => ({ status: 'approved', incidentVerification: 'verified', reporterUid,
    incidentAt: new Date('2026-09-19'), mapId: 'blue_gate', verifiedEvidence: { contentHash: 'same' } }));
  assert.equal(deriveIntelligence(rows, NOW).verifiedIncidentCount, 1);
  assert.equal(deriveIntelligence(rows, NOW).confidence, 'LOW');
});
test('rejected allegation stays undiscoverable; an upheld challenge preserves the verified incident', async () => {
  const rejected = harness(); const ids = await pending(rejected);
  await rejected.api.moderateReport(req('mod', { reportId: ids.reportId, approve: false, notes: 'Unsupported allegation.' }));
  assert.equal((await rejected.api.accountStatus(req('target'))).cases[0].status, 'rejected');
  assert.equal((await rejected.api.discover(req('hunter'))).contracts.length, 0);
  const upheld = harness(); const activeIds = await active(upheld);
  await upheld.api.challenge(req('target', { contractId: activeIds.contractId, reason: 'Please independently review this case.' }));
  await upheld.api.reviewChallenge(req('mod', { contractId: activeIds.contractId, overturn: false, notes: 'Independent review confirms the incident.' }));
  assert.equal(upheld.store.get(`arc_raider_contracts/${activeIds.contractId}`).status, 'available');
  assert.equal((await upheld.api.accountStatus(req('target'))).cases[0].challengeStatus, 'upheld');
});
test('request-supplied user identity never changes account or discovery authority', async () => {
  const h = harness(); const ids = await active(h);
  assert.equal((await h.api.discover(req('target', { uid: 'hunter', targetUid: 'other', search: 'Target Name' }))).contracts.length, 0);
  const cases = (await h.api.accountStatus(req('other', { uid: 'target', contractId: ids.contractId }))).cases;
  assert.deepEqual(cases, []);
  await denied(h.api.discover({ data: {} }), 'unauthenticated');
});