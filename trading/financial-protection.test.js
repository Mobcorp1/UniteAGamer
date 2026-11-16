'use strict';
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { ref, uploadBytes } = require('firebase/storage');
const admin = require('firebase-admin');
const { HttpsError } = require('firebase-functions/v2/https');
const { createFinancialProtection, CONTROL_PATH } = require('../functions/financial_protection');

async function run() {
  if (!/^127\.0\.0\.1:/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) throw Error('Local Firestore emulator required');
  const projectId = 'demo-uag-financial-protection';
  const env = await initializeTestEnvironment({ projectId,
    firestore: { rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') },
    storage: { rules: fs.readFileSync(path.join(__dirname, '../storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 } });
  const app = admin.initializeApp({ projectId }, 'financial-integration');
  let checks = 0;
  const yes = async p => { await assertSucceeds(p); checks++; };
  const no = async p => { await assertFails(p); checks++; };
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async ctx => {
      for (const uid of ['user', 'recipient', 'admin']) await ctx.firestore().doc(`users/${uid}`).set({
        isAdmin: uid === 'admin', isDev: false, isModerator: false, ageVerification: { verifiedOver18: true } });
    });
    const user = env.authenticatedContext('user').firestore();
    const operator = env.authenticatedContext('admin').firestore();
    const guest = env.unauthenticatedContext().firestore();
    for (const role of ['isAdmin', 'isDev', 'isModerator']) {
      await no(user.doc('users/user').update({ [role]: true }));
      await no(env.authenticatedContext(`new-${role}`).firestore().doc(`users/new-${role}`).set({ [role]: true }));
    }
    await yes(user.doc('users/user').update({ displayName: 'Raider' }));
    await yes(user.doc('users/user/arc_blueprints/example').set({ owned: true, dupesOwned: 2 }));
    await no(user.doc('users/user/monetisation_usage/community_referral_attribution').set({ referrerUid: 'forged' }));
    await no(user.doc('users/user/notifications/forged').set({ title: 'Forged server notification' }));
    await no(user.doc('users/user/notification_devices/device').set({ userId: 'someone-else', deviceId: 'device' }));
    await yes(user.doc('users/user/notification_preferences/preferences').set({ enabled: true }));
    await no(user.doc('users/user/notification_preferences/preferences').delete());
    await yes(user.doc('users/user/arc_season_history/season').set({ seasonId: 'season' }));
    await no(user.doc('users/user/arc_season_history/season').delete());
    await yes(user.doc('users/user/arc_item_recommendation_logs/item').set({ uid: 'user' }));
    await no(user.doc('users/user/arc_item_recommendation_logs/item').update({ uid: 'someone-else' }));
    for (const db of [user, operator, guest]) {
      await no(db.doc(CONTROL_PATH).set({ active: false }));
      await no(db.doc('financial_protection_audit/forged').set({ active: false }));
      await no(db.doc('financial_operation_limits/forged').set({ count: 0 }));
    }
    const message = id => user.doc(`uag_message_outbox/${id}`).set({ id, senderUid: 'user', recipientUid: 'recipient', status: 'queued', body: 'Hello' });
    await yes(message('before'));
    const service = createFinancialProtection({ db: app.firestore(), HttpsError,
      auth: { getUser: async () => ({ disabled: false }) }, timestamp: () => admin.firestore.FieldValue.serverTimestamp() });
    const request = { auth: { uid: 'admin' }, data: { active: true, reason: 'Local simulated traffic protection test', expectedRevision: 0, requestId: 'emulator-request-0001' } };
    const results = await Promise.all([service.setRestriction(request), service.setRestriction(request)]);
    assert.equal(results[0].revision, 1); assert.equal(results[1].revision, 1); checks++;
    await no(message('blocked'));
    await no(operator.doc('notification_broadcasts/blocked').set({ id: 'blocked', senderUid: 'admin', status: 'queued' }));
    await no(user.doc('financial_protection_audit/emulator-request-0001').get());
    await yes(operator.doc('financial_protection_audit/emulator-request-0001').get());
    await yes(user.doc('users/user').get());
    await yes(user.doc('users/user/arc_blueprints/example').update({ dupesOwned: 3 }));
    const storage = env.authenticatedContext('user').storage();
    await no(uploadBytes(ref(storage, 'users/user/creator_content/blocked.png'), new Uint8Array(20), { contentType: 'image/png' }));
    await yes(uploadBytes(ref(storage, 'users/user/profile_media/account.png'), new Uint8Array(20), { contentType: 'image/png' }));
    await service.setRestriction({ ...request, data: { ...request.data, active: false, expectedRevision: 1, requestId: 'emulator-request-0002' } });
    await yes(message('after'));
    await yes(uploadBytes(ref(storage, 'users/user/creator_content/allowed.png'), new Uint8Array(20), { contentType: 'image/png' }));
    let calls = 0;
    const guarded = service.protectCallable('expensive-test', 3, () => ++calls);
    const burst = await Promise.allSettled(Array.from({ length: 12 }, () => guarded({ auth: { uid: 'user' } })));
    assert.equal(burst.filter(x => x.status === 'fulfilled').length, 3); assert.equal(calls, 3); checks++;
    assert.equal((await app.firestore().collection('financial_operation_limits').get()).size, 1); checks++;
    // Exercise the actual deployed trigger handler against local Firestore:
    // cross the 200-document page boundary, replay the same event, then stop.
    const { notifyAutomaticTradingWatches } = require('../functions/index');
    const batch = app.firestore().batch();
    for (let i = 0; i < 205; i++) batch.set(app.firestore().doc(`trading_watch_preferences/raider-${String(i).padStart(3, '0')}`), { tradeItemIds: ['metal-parts'] });
    await batch.commit();
    const event = { params: { listingId: 'pagination-test' }, data: { data: () => ({ active: true, ownerUid: 'seller', offeredTradeItemIds: ['metal-parts'] }) } };
    await notifyAutomaticTradingWatches.run(event);
    assert.equal((await app.firestore().collection('trading_notifications').get()).size, 205); checks++;
    await notifyAutomaticTradingWatches.run(event);
    assert.equal((await app.firestore().collection('trading_notifications').get()).size, 205); checks++;
    await service.setRestriction({ ...request, data: { ...request.data, expectedRevision: 2, requestId: 'emulator-request-0003' } });
    // The trigger instance caches for at most five seconds.
    await new Promise(resolve => setTimeout(resolve, 5100));
    await notifyAutomaticTradingWatches.run({ ...event, params: { listingId: 'blocked-pagination' } });
    assert.equal((await app.firestore().collection('trading_notifications').get()).size, 205); checks++;
    await require('../functions/node_modules/firebase-admin').app().delete();
    console.log(`Financial protection emulator checks: ${checks} passed`);
  } finally { await env.cleanup(); await app.delete(); }
}
run().catch(error => { console.error(error); process.exitCode = 1; });
