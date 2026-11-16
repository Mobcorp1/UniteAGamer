'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buildGateway } = require('../uag_trade_invite_gateway');
function harness(options = {}) {
  let reads = 0, authCalls = 0;
  const gateway = buildGateway({ admin: { firestore: { FieldValue: {}, Timestamp: {} } },
    db: { collection: () => { reads++; throw Error('unexpected database access'); } },
    auth: { verifyIdToken: async () => { authCalls++; throw Error('invalid'); } }, ...options });
  return { readCount: () => reads, authCount: () => authCalls, async call(body, headers = {}) {
    const out = { status: 0, body: null, headers: {} };
    const res = { set: (k, v) => { out.headers[k] = v; }, status: code => { out.status = code; return res; },
      json: value => { out.body = value; }, send: value => { out.body = value; } };
    await gateway({ method: 'POST', ip: '127.0.0.1', is: () => true, body, headers }, res); return out;
  } };
}
test('public shield and input bounds reject requests before database or auth work', async () => {
  const h = harness({ allowRequest: () => false });
  assert.equal((await h.call({ action: 'resolve' })).status, 429); assert.equal(h.readCount(), 0); assert.equal(h.authCount(), 0);
  const input = harness(); assert.equal((await input.call({ action: 'resolve', token: 'x'.repeat(5000) })).status, 413);
  assert.equal((await input.call({ action: 'unknown' })).status, 400); assert.equal(input.readCount(), 0);
});
test('App Check enforcement option rejects missing/invalid attestation and allows valid tokens to reach ordinary validation', async () => {
  const h = harness({ requireAppCheck: true, appCheck: { verifyToken: async token => { if (token !== 'valid') throw Error('invalid'); } } });
  assert.equal((await h.call({ action: 'resolve' })).status, 401);
  assert.equal((await h.call({ action: 'resolve' }, { 'x-firebase-appcheck': 'forged' })).status, 401);
  assert.equal((await h.call({ action: 'resolve', token: 'invalid-shape' }, { 'x-firebase-appcheck': 'valid' })).status, 404);
  assert.equal(h.readCount(), 0);
});
test('emergency fails closed with readable response and authentication remains required', async () => {
  const h = harness({ financialProtection: { assertAvailable: async () => { throw Object.assign(Error('Temporarily unavailable'), { code: 'unavailable' }); } } });
  assert.equal((await h.call({ action: 'resolve' })).status, 503);
  assert.equal((await h.call({ action: 'create' })).status, 401); assert.equal(h.readCount(), 0);
});
