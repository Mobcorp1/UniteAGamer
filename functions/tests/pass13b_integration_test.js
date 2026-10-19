'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { liveListing, watchFitsListing, freshLooking, riderFits, buildHandlers } = require('../uag_pass13_auto_matches');
const now = Date.now();
const stamp = (ms) => ({ toMillis: () => ms });
const watch = { ownerUid: 'buyer', active: true, notificationsEnabled: true,
  notificationPreference: 'immediate', type: 'blueprint', blueprintId: 'anvil' };
const listing = { ownerUid: 'seller', active: true, expiresAt: stamp(now + 60_000),
  offeredBlueprintNames: ['Anvil'], listingMode: 'availableNow' };
const rider = (uid, patch = {}) => ({ uid, visibleInSearch: true, lookingNow: true,
  autoMatchAlertsEnabled: true, updatedAt: stamp(now - 30_000), region: 'EU', platform: 'PS5',
  crossplayEnabled: true, serverPreference: 'Automatic', preferredEvents: ['ARC Frigate'],
  ...patch });

test('trade alerts never match expired, inactive, self-owned or muted watches', () => {
  assert.ok(liveListing(listing));
  assert.ok(watchFitsListing(watch, listing));
  assert.equal(watchFitsListing(watch, { ...listing, active: false }), false);
  assert.equal(watchFitsListing(watch, { ...listing, expiresAt: stamp(1) }), false);
  assert.equal(watchFitsListing({ ...watch, blueprintId: 'Rascal', blueprintDisplayName: 'Rascal' }, listing), false);
  assert.equal(watchFitsListing({ ...watch, ownerUid: 'seller' }, listing), false);
  assert.equal(watchFitsListing({ ...watch, notificationPreference: 'muted' }, listing), false);
});
test('squad matching requires fresh, mutual opt-in and compatible event', () => {
  assert.ok(riderFits(rider('a'), rider('b'), now));
  assert.equal(freshLooking(rider('a', { updatedAt: stamp(now - 8*60*60*1000) }), now), false);
  assert.equal(riderFits(rider('a'), rider('b', { preferredEvents: ['Redirection'] }), now), false);
  assert.equal(riderFits(rider('a'), rider('b', { autoMatchAlertsEnabled: false }), now), false);
  assert.equal(riderFits(rider('a'), rider('b', { crossplayEnabled: false, platform: 'PC' }), now), false);
  assert.equal(riderFits(rider('a'), rider('b', { region: 'NA' }), now), false);
  assert.equal(riderFits(rider('a', { blockedMatchRiderUids: ['b'] }), rider('b'), now), false);
});

function fakeDb({ control = {}, users = {}, preferences = {}, collections = {}, blocks = [] } = {}) {
  const notices = new Map();
  const operations = [];
  const db = {
    collection(path) {
      if (path === 'trading_notifications') return {
        doc(id) { return { id, async create(data) {
          if (notices.has(id)) { const e = new Error('already exists'); e.code = 6; throw e; }
          notices.set(id, data);
        } }; },
      };
      if (path === 'uag_release_controls') return {
        doc(id) { return { async get() { return { data: () => id === 'launch_matching' ? control : {} }; } }; },
      };
      if (path === 'uag_user_blocks') return {
        doc(id) { return { async get() { return { exists: blocks.includes(id) }; } }; },
      };
      if (path === 'users') return {
        doc(uid) { return { async get() { return { data: () => users[uid] }; },
          collection(name) { assert.equal(name, 'notification_preferences'); return {
            doc(id) { assert.equal(id, 'current'); return { async get() { return { data: () => preferences[uid] }; } }; },
          }; },
        }; },
      };
      const items = collections[path] || [];
      const make = (cursor, pageSize) => ({
        orderBy() { return make(cursor, pageSize); },
        startAfter(last) { return make(items.indexOf(last) + 1, pageSize); },
        limit(n) { return make(cursor, n); },
        async get() { const docs = items.slice(cursor, cursor + pageSize); operations.push([path,cursor,docs.length]);
          return { docs, size: docs.length }; },
      });
      return make(0, 250);
    },
  };
  return { db, notices, operations };
}
const user = () => ({ ageVerification: { verifiedOver18: true } });
const admin = { firestore: { FieldValue: { serverTimestamp: () => 'SERVER_TIMESTAMP' } },
  auth: () => ({ getUser: async () => ({ disabled: false }) }) };
const doc = (id, obj) => ({ id, exists: true, data: () => obj });
const qaControl = (flags, uids) => ({ enabled:true, qaMode:'testers', publicEnabled:false, testerUids:uids, qaExpiresAt:new Date(Date.now()+86400000), ...flags });

test('default-off release gate: no matchmaking and no trade notifications', async () => {
  const { db, notices } = fakeDb({ collections: {
    trading_listings: [doc('listingA', listing)],
    arc_blueprint_watches: [doc('watchA', watch)],
    arc_match_rider_profiles: [doc('a',rider('a')),doc('b',rider('b'))],
  }});
  const handler = buildHandlers(db, admin);
  await handler.onListing({ data: { after: doc('listingA', listing) } });
  await handler.onRider({ data: { after: doc('a', rider('a')) } });
  assert.equal(notices.size, 0);
});

test('trade notification respects age, blocks, current preference and idempotency', async () => {
  const env = fakeDb({ control: qaControl({tradeAlertsEnabled:true},['buyer','seller']),
    users: { buyer: user(), seller: user() },
    collections: { arc_blueprint_watches: [doc('watchA',watch)] } });
  const h = buildHandlers(env.db,admin);
  const evt = { data: { after: doc('listingA',listing) } };
  await h.onListing(evt);
  await h.onListing(evt);
  assert.equal(env.notices.size,1);
  const data = [...env.notices.values()][0];
  assert.equal(data.broadcastPushHandled,false);
  assert.equal(data.listingId,'listingA');
  const muted = fakeDb({ control: qaControl({tradeAlertsEnabled:true},['buyer','seller']),
    users: {buyer:user(), seller:user()}, preferences: { buyer: { watchesAndQueues: false } },
    collections:{ arc_blueprint_watches:[doc('watchA',watch)] } });
  await buildHandlers(muted.db,admin).onListing(evt);
  assert.equal(muted.notices.size,0);
  const blocked = fakeDb({ control: qaControl({tradeAlertsEnabled:true},['buyer','seller']),
    users: {buyer:user(), seller:user()}, blocks:['buyer_seller'],
    collections:{ arc_blueprint_watches:[doc('watchA',watch)] } });
  await buildHandlers(blocked.db,admin).onListing(evt);
  assert.equal(blocked.notices.size,0);
});

test('six-hour stale expiry prevents squad notifications and enabled pair sends two deduped alerts', async () => {
  const control = qaControl({squadAlertsEnabled:true},['a','b']);
  const env = fakeDb({control,users:{a:user(),b:user()},
    collections:{arc_match_rider_profiles:[doc('a',rider('a')),doc('b',rider('b'))]}});
  const h = buildHandlers(env.db,admin);
  const evt = { data:{after:doc('a',rider('a'))} };
  await h.onRider(evt);await h.onRider(evt);
  assert.equal(env.notices.size,2);
  assert.deepEqual([...env.notices.values()].map(x=>x.targetUid).sort(),['a','b']);
  const old = fakeDb({control,users:{a:user(),b:user()},collections:{arc_match_rider_profiles:[doc('b',rider('b',{updatedAt:stamp(now-10*60*60*1000)}))]}});
  await buildHandlers(old.db,admin).onRider(evt);
  assert.equal(old.notices.size,0);
});
