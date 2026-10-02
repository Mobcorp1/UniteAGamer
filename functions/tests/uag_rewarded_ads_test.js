'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const { createRewardHandlers, verifyCallback, effectiveTier, normalizedWallet,
  assertCanEarn, LIVE_UNIT, TEST_UNIT, PLACEMENT } = require('../uag_rewarded_ads');
const NOW = Date.UTC(2026, 9, 1, 12);
const { publicKey, privateKey } = crypto.generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
const keys = async () => new Map([['7', publicKey]]);
function callback(data, mutate = value => value) {
  const signed = new URLSearchParams(data).toString();
  const signature = crypto.sign('sha256', Buffer.from(signed), privateKey).toString('base64url');
  return `/verify?${mutate(signed)}&signature=${signature}&key_id=7`;
}
class MemoryDb {
  constructor() { this.docs = new Map(); this.queue = Promise.resolve(); }
  collection(name) { return this.collectionAt(name); }
  collectionAt(path) { return { doc: id => this.ref(`${path}/${id}`) }; }
  ref(path) { return { path, collection: name => this.collectionAt(`${path}/${name}`) }; }
  snapshot(ref) { const value = this.docs.get(ref.path); return { exists: value !== undefined, data: () => value }; }
  runTransaction(fn) {
    const run = this.queue.then(async () => {
      const writes = [];
      const result = await fn({ get: async ref => this.snapshot(ref),
        set: (ref, data, options) => writes.push({ ref, data, options }) });
      for (const {ref, data, options} of writes) this.docs.set(ref.path,
        options?.merge ? { ...this.docs.get(ref.path), ...data } : data);
      return result;
    });
    this.queue = run.catch(() => {});
    return run;
  }
}
function fixture() {
  const db = new MemoryDb();
  db.docs.set('users/u', { subscriptionStatus: 'inactive' });
  db.docs.set('app_config/ads', { adsEnabled: true, rewardedEnabled: true,
    rewardedSsvReady: true, productionAdsEnabled: true, forceTestAds: false });
  const auth = { verifyIdToken: async token => {
    if (token !== 'valid') { const e = new Error(); e.code = 'auth/invalid-id-token'; throw e; }
    return { uid: 'u' };
  }};
  const handlers = createRewardHandlers({ db, auth, now: () => NOW, keyProvider: keys });
  return { db, handlers };
}
async function invoke(fn, body, options = {}) {
  const result = {};
  const res = { status: status => { result.status = status; return res; },
    json: body => { result.body = body; }, send: body => { result.body = body; } };
  await fn({ method: 'POST', headers: { authorization: 'Bearer valid' }, body, ...options }, res);
  return result;
}
async function prepare(f, inventory = 'live') {
  const r = await invoke(f.handlers.prepare, { placement: PLACEMENT, inventory });
  assert.equal(r.status, 200, JSON.stringify(r.body)); return r.body.sessionId;
}
async function grant(f, session, overrides = {}, transaction = 'abc123') {
  const event = { ad_network: '5450213213286189855', ad_unit: LIVE_UNIT,
    custom_data: session, reward_amount: '1', reward_item: 'Raider Mark',
    timestamp: String(NOW), transaction_id: transaction, user_id: 'u', ...overrides };
  return invoke(f.handlers.ssv, {}, { method: 'GET', originalUrl: callback(event) });
}
test('ECDSA signature verifies original percent-escaped query bytes', async () => {
  const url = callback({ ad_unit: LIVE_UNIT, custom_data: 'a'.repeat(32), reward_amount: 1,
    timestamp: NOW, transaction_id: 'abc123', user_id: 'u', reward_item: 'Raider Mark + reward' });
  assert.equal((await verifyCallback(url, keys)).reward_item, 'Raider Mark + reward');
  await assert.rejects(verifyCallback(url.replace('reward_amount=1', 'reward_amount=2'), keys));
  await assert.rejects(verifyCallback(url.replace('key_id=7', 'key_id=9'), keys));
  await assert.rejects(verifyCallback(url + '&injected=1', keys));
});
test('duplicate signed parameters cannot override identities', async () => {
  const raw = 'ad_unit=' + encodeURIComponent(LIVE_UNIT) + '&custom_data=' + 'a'.repeat(32) +
    '&reward_amount=1&timestamp=' + NOW + '&transaction_id=abc&user_id=u&user_id=v';
  const sig = crypto.sign('sha256', Buffer.from(raw), privateKey).toString('base64url');
  await assert.rejects(verifyCallback('/x?' + raw + '&signature=' + sig + '&key_id=7', keys));
});
test('paid subscriptions, passes, creator rewards, admin and test tiers mirror entitlement', () => {
  assert.equal(effectiveTier({ subscriptionTier: 'premium', subscriptionStatus: 'inactive' }, NOW), 'free');
  assert.equal(effectiveTier({ subscriptionTier: 'active_raider', subscriptionStatus: 'active' }, NOW), 'essential');
  assert.equal(effectiveTier({ premiumPass: { type: 'day24', expiresAt: NOW + 1 } }, NOW), 'premium');
  assert.equal(effectiveTier({ isAdmin: true }, NOW), 'premium');
  assert.equal(effectiveTier({ isDev: true, entitlementTest: { mode: 'free' } }, NOW), 'free');
  assert.equal(effectiveTier({ creatorRewardEntitlements: { x: { tier: 'essential', startedAt: NOW - 1, expiresAt: NOW + 1 } } }, NOW), 'essential');
});
test('monthly/day rollover preserves marks and cooldown', () => {
  const wallet = normalizedWallet({ balance: 7, day: '2026-09-30', month: '2026-09',
    adsToday: 3, adsThisMonth: 20, redemptionsThisMonth: 4, lastVerifiedAt: NOW - 100 }, NOW);
  assert.equal(wallet.balance, 7); assert.equal(wallet.adsToday, 0);
  assert.equal(wallet.adsThisMonth, 0); assert.equal(wallet.redemptionsThisMonth, 0);
  assert.throws(() => assertCanEarn(wallet, NOW), /20 minutes/);
  assert.doesNotThrow(() => assertCanEarn({ ...wallet, lastVerifiedAt: NOW - 1200000 }, NOW));
  for (const change of [{ balance: 10 }, { adsToday: 3 }, { adsThisMonth: 20 }, { lastVerifiedAt: NOW + 1 }]) {
    assert.throws(() => assertCanEarn({ ...wallet, lastVerifiedAt: 0, ...change }, NOW));
  }
});
test('unauthenticated and paid clients cannot reserve rewards', async () => {
  const f = fixture();
  assert.equal((await invoke(f.handlers.prepare, {}, { headers: {} })).status, 401);
  assert.equal((await invoke(f.handlers.prepare, {}, { headers: { authorization: 'Bearer invalid' } })).status, 401);
  f.db.docs.set('users/u', { subscriptionStatus: 'active', subscriptionTier: 'premium' });
  assert.equal((await invoke(f.handlers.prepare, { placement: PLACEMENT, inventory: 'live' })).status, 403);
});
test('remote live/test and SSV release gates fail closed', async () => {
  for (const change of [{ productionAdsEnabled: false }, { forceTestAds: true }, { rewardedSsvReady: false }, { rewardedEnabled: false }, { adsEnabled: false }]) {
    const f = fixture(); f.db.docs.set('app_config/ads', { ...f.db.docs.get('app_config/ads'), ...change });
    assert.notEqual((await invoke(f.handlers.prepare, { placement: PLACEMENT, inventory: 'live' })).status, 200);
  }
});
test('concurrent taps reserve only one session', async () => {
  const f = fixture(); const attempts = await Promise.all([1, 2, 3].map(() =>
    invoke(f.handlers.prepare, { placement: PLACEMENT, inventory: 'live' })));
  assert.equal(attempts.filter(r => r.status === 200).length, 1);
});
test('only verified callbacks grant; duplicate callbacks grant once', async () => {
  const f = fixture(), session = await prepare(f);
  assert.equal(f.db.docs.get('uag_reward_wallets/u').balance, 0);
  const results = await Promise.all([grant(f, session), grant(f, session), grant(f, session)]);
  assert.ok(results.every(r => r.status === 200));
  assert.equal(f.db.docs.get('uag_reward_wallets/u').balance, 1);
  assert.equal(f.db.docs.get('uag_reward_wallets/u').adsToday, 1);
  assert.equal(f.db.docs.get(`uag_reward_sessions/${session}`).status, 'verified');
});
test('identity, unit, amount, timestamp and cancelled sessions reject reward forgery', async () => {
  for (const change of [{ user_id: 'other' }, { ad_unit: TEST_UNIT }, { reward_amount: '2' },
    { timestamp: String(NOW - 120000) }, { timestamp: String(NOW + 120000) }]) {
    const f = fixture(), session = await prepare(f);
    assert.notEqual((await grant(f, session, change)).status, 200);
    assert.equal(f.db.docs.get('uag_reward_wallets/u').balance, 0);
  }
  const f = fixture(), session = await prepare(f);
  await invoke(f.handlers.cancel, { sessionId: session });
  assert.notEqual((await grant(f, session)).status, 200);
  assert.equal(f.db.docs.get('uag_reward_wallets/u').pendingSession, null);
});
test('Google test inventory cannot grant production marks', async () => {
  const f = fixture(), session = await prepare(f, 'test');
  assert.equal((await grant(f, session, { ad_unit: TEST_UNIT })).status, 200);
  assert.equal(f.db.docs.get('uag_reward_test_wallets/u').balance, 1);
  assert.equal(f.db.docs.has('uag_reward_wallets/u'), false);
});
test('earned reward survives upgrade during ad but not deleted account', async () => {
  const f = fixture(), session = await prepare(f);
  f.db.docs.set('users/u', { subscriptionStatus: 'active', subscriptionTier: 'premium' });
  assert.equal((await grant(f, session)).status, 200);
  const g = fixture(), deleted = await prepare(g); g.db.docs.delete('users/u');
  assert.equal((await grant(g, deleted)).status, 410);
});
test('redemption is atomic and retry-safe and augments canonical monthly allowance', async () => {
  const f = fixture(); f.db.docs.set('uag_reward_wallets/u', { balance: 10 });
  const first = { action: 'trades', requestId: 'a'.repeat(32) };
  const second = { action: 'matchmakingSearches', requestId: 'b'.repeat(32) };
  const results = await Promise.all([invoke(f.handlers.redeem, first), invoke(f.handlers.redeem, first), invoke(f.handlers.redeem, second)]);
  assert.ok(results.every(r => r.status === 200));
  assert.equal(f.db.docs.get('uag_reward_wallets/u').balance, 0);
  assert.equal(f.db.docs.get('uag_reward_wallets/u').redemptionsThisMonth, 2);
  assert.deepEqual(f.db.docs.get('uag_reward_bonuses/u/months/2026-M10'), { uid: 'u', periodKey: '2026-M10', trades: 1, matchmakingSearches: 1 });
  assert.equal((await invoke(f.handlers.redeem, { ...first, action: 'matchmakingSearches' })).status, 409);
  assert.equal((await invoke(f.handlers.redeem, { action: 'trades', requestId: 'c'.repeat(32) })).status, 409);
});
test('redemption protects paid lanes, 4/month cap and supported actions', async () => {
  const body = { action: 'trades', requestId: 'c'.repeat(32) };
  const f = fixture(); f.db.docs.set('uag_reward_wallets/u', { balance: 10, month: '2026-10', redemptionsThisMonth: 4 });
  assert.equal((await invoke(f.handlers.redeem, body)).status, 429);
  f.db.docs.set('users/u', { isAdmin: true });
  assert.equal((await invoke(f.handlers.redeem, body)).status, 403);
  assert.equal((await invoke(f.handlers.redeem, { ...body, action: 'premiumIntelUnlocks' })).status, 400);
});
