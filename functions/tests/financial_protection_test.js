'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { createFinancialProtection, createLocalRateLimit, CONTROL_PATH } = require('../financial_protection');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
function fixture() {
  const docs = new Map([['users/admin', { isAdmin: true }]]);
  const state = { now: 10000, reads: 0, writes: 0, unavailable: false, disabled: false };
  const snap = path => ({ exists: docs.has(path), data: () => docs.get(path) });
  const ref = path => ({ path, get: async () => { state.reads++; if (state.unavailable) throw Error('offline'); return snap(path); } });
  let serial = Promise.resolve();
  const db = { doc: ref, collection: path => ({ doc: id => ref(`${path}/${id}`) }), runTransaction: fn => {
    const result = serial.then(async () => {
      const writes = [];
      const value = await fn({ get: r => r.get(), set: (r, d) => writes.push([r.path, d]),
        create: (r, d) => { assert(!docs.has(r.path)); writes.push([r.path, d]); } });
      for (const [p, d] of writes) { docs.set(p, d); state.writes++; } return value;
    }); serial = result.catch(() => {}); return result;
  } };
  return { docs, state, api: createFinancialProtection({ db, auth: { getUser: async () => ({ disabled: state.disabled }) },
    HttpsError, timestamp: () => 'SERVER', now: () => state.now }) };
}
const adminRequest = (data = {}) => ({ auth: { uid: 'admin' }, data: {
  active: true, reason: 'Unexpected usage investigation', expectedRevision: 0, requestId: 'unique-request-0001', ...data } });

test('coalesces checks, refreshes after five seconds and fails closed on malformed or unavailable controls', async () => {
  const h = fixture(); assert.deepEqual(await Promise.all(Array.from({ length: 100 }, () => h.api.restricted())), Array(100).fill(false));
  assert.equal(h.state.reads, 1); h.docs.set(CONTROL_PATH, { active: true }); h.state.now += 5000;
  assert.equal(await h.api.restricted(), true); h.docs.set(CONTROL_PATH, {}); h.state.now += 5000;
  assert.equal(await h.api.restricted(), true); h.state.unavailable = true; h.state.now += 5000;
  assert.equal(await h.api.restricted(), true); assert.equal(await h.api.restricted(), true); assert.equal(h.state.reads, 4);
  h.state.unavailable = false; h.docs.set(CONTROL_PATH, { active: false }); h.state.now += 5000;
  assert.equal(await h.api.restricted(), false);
});
test('authentication, emergency restriction and transactional rate limit run before expensive work', async () => {
  const h = fixture(); let calls = 0; const run = h.api.protectCallable('video', 2, () => ++calls);
  await assert.rejects(run({}), e => e.code === 'unauthenticated'); assert.equal(h.state.reads, 0);
  const results = await Promise.allSettled(Array.from({ length: 20 }, () => run({ auth: { uid: 'u' } })));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 2); assert.equal(calls, 2); assert.equal(h.state.writes, 2);
  h.state.now += 60000; await run({ auth: { uid: 'u' } }); assert.equal(calls, 3);
  h.docs.set(CONTROL_PATH, { active: true }); h.state.now += 5000;
  await assert.rejects(run({ auth: { uid: 'u' } }), e => e.code === 'unavailable'); assert.equal(calls, 3);
});
test('admin changes are atomic, audited, revision-checked and idempotent', async () => {
  const h = fixture(); await h.api.restricted();
  await assert.rejects(h.api.setRestriction({ ...adminRequest(), auth: { uid: 'user' } }), e => e.code === 'permission-denied');
  const [a, b] = await Promise.all([h.api.setRestriction(adminRequest()), h.api.setRestriction(adminRequest())]);
  assert.deepEqual(a, b); assert.equal(a.revision, 1); assert.equal(h.state.writes, 2);
  assert.equal(await h.api.restricted(), true);
  await assert.rejects(h.api.setRestriction(adminRequest({ active: false })), e => e.code === 'already-exists');
  await assert.rejects(h.api.setRestriction(adminRequest({ requestId: 'unique-request-0002' })), e => e.code === 'aborted');
  await h.api.setRestriction(adminRequest({ active: false, requestId: 'unique-request-0002', expectedRevision: 1 }));
  assert.equal(await h.api.restricted(), false); assert.equal(h.docs.get('financial_protection_audit/unique-request-0002').previousActive, true);
  h.state.disabled = true; await assert.rejects(h.api.setRestriction(adminRequest()), e => e.code === 'permission-denied');
});
test('control rejects invalid input and ordinary user-supplied role claims', async () => {
  const h = fixture();
  for (const data of [{ active: 'false' }, { reason: 'x' }, { expectedRevision: -1 }, { requestId: '../escape' }]) {
    await assert.rejects(h.api.setRestriction(adminRequest(data)), e => e.code === 'invalid-argument');
  }
  await assert.rejects(h.api.setRestriction({ ...adminRequest(), auth: { uid: 'user', token: { isAdmin: true } } }), e => e.code === 'permission-denied');
  assert.equal(h.state.writes, 0);
});
test('public endpoint shield bounds both request rate and memory without database work', () => {
  let now = 0; const allow = createLocalRateLimit({ maximum: 2, capacity: 2, windowMs: 1000, now: () => now });
  assert(allow('a')); assert(allow('a')); assert(!allow('a')); assert(allow('b')); assert(!allow('c'));
  now = 1000; assert(allow('c')); assert(allow('a'));
});
