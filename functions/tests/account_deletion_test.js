'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  accountDeletionKey,
  retainedSubjectKey,
  isRecentAuth,
  createAccountDeletionLifecycle,
} = require('../account_deletion');

class HttpsError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const DELETE_FIELD = Symbol('delete-field');

function harness() {
  const store = new Map();
  const deletedAuth = [];
  const storagePrefixes = [];
  const now = new Date('2026-09-21T15:00:00Z');

  function clone(value) {
    if (value === undefined) return undefined;
    return structuredClone(value);
  }

  function directChildren(path) {
    const prefix = `${path}/`;
    const depth = path.split('/').length + 1;
    return [...store.keys()]
      .filter((key) => key.startsWith(prefix) && key.split('/').length === depth)
      .sort();
  }

  function applyPatch(current, patch) {
    const next = { ...(current || {}) };
    for (const [key, value] of Object.entries(patch || {})) {
      if (value === DELETE_FIELD) delete next[key];
      else next[key] = clone(value);
    }
    return next;
  }

  function docRef(path) {
    return {
      path,
      async get() {
        return snapshot(path);
      },
      async set(value, options = {}) {
        const current = store.get(path);
        store.set(
          path,
          options.merge ? applyPatch(current, value) : clone(value),
        );
      },
      async delete() {
        store.delete(path);
      },
      async listCollections() {
        const prefix = `${path}/`;
        const docDepth = path.split('/').length;
        const names = new Set();
        for (const key of store.keys()) {
          if (!key.startsWith(prefix)) continue;
          const segments = key.split('/');
          if (segments.length >= docDepth + 2) {
            names.add(segments[docDepth]);
          }
        }
        return [...names].map((name) => collectionRef(`${path}/${name}`));
      },
    };
  }

  function snapshot(path) {
    return {
      id: path.split('/').pop(),
      ref: docRef(path),
      exists: store.has(path),
      data: () => clone(store.get(path)),
    };
  }

  function queryRef(path, filters = [], limitCount = null) {
    return {
      where(field, op, value) {
        return queryRef(path, [...filters, [field, op, value]], limitCount);
      },
      limit(value) {
        return queryRef(path, filters, value);
      },
      async get() {
        let docs = directChildren(path)
          .map(snapshot)
          .filter((snap) => {
            const data = snap.data() || {};
            return filters.every(([field, op, value]) => {
              if (op === '==') return data[field] === value;
              if (op === 'array-contains') {
                return Array.isArray(data[field]) && data[field].includes(value);
              }
              throw new Error(`Unsupported op ${op}`);
            });
          });
        if (limitCount != null) docs = docs.slice(0, limitCount);
        return { empty: docs.length === 0, docs };
      },
    };
  }

  function collectionRef(path) {
    return {
      path,
      doc(id) {
        return docRef(`${path}/${id}`);
      },
      where(field, op, value) {
        return queryRef(path, [[field, op, value]]);
      },
      limit(value) {
        return queryRef(path, [], value);
      },
      get() {
        return queryRef(path).get();
      },
    };
  }

  const db = {
    collection: collectionRef,
    collectionGroup(name) {
      return {
        where(field, op, value) {
          return {
            limit() {
              return this;
            },
            async get() {
              const docs = [...store.keys()]
                .filter((path) => {
                  const segments = path.split('/');
                  return segments.length >= 2 &&
                    segments[segments.length - 2] === name;
                })
                .map(snapshot)
                .filter((snap) => {
                  const data = snap.data() || {};
                  return op === '==' && data[field] === value;
                });
              return { empty: docs.length === 0, docs };
            },
          };
        },
      };
    },
  };

  store.set('users/u', { email: 'user@example.test', displayName: 'User' });
  store.set('users/u/personalisation/current', { goals: ['tradeBlueprints'] });
  store.set('public_profiles/u', { uid: 'u', displayName: 'User' });
  store.set('supporter_entitlements/u', { uid: 'u', active: true });
  store.set('uag_ids/UAG000000001', { uid: 'u', uagId: 'UAG000000001' });
  store.set('uag_creator_applications/a', { uid: 'u', status: 'pending' });
  store.set('trading_listings/l', { ownerUid: 'u', active: true });
  store.set('trading_sessions/s', {
    traderOneUid: 'u',
    traderTwoUid: 'other',
    traderOneName: 'User',
    traderTwoName: 'Other',
    traderOneEmbarkId: 'private',
    traderTwoEmbarkId: 'other-id',
    traderOneSharedEmbarkId: true,
    traderTwoSharedEmbarkId: true,
    status: 'ready',
    firstDropUid: 'u',
  });
  store.set('arc_raider_reports/r', {
    reporterUid: 'other',
    targetUid: 'u',
    targetDisplayName: 'User',
    status: 'approved',
    incidentVerification: 'verified',
  });
  store.set('arc_community_intel_reports/i', {
    reporterUid: 'other',
    confirmedByUserIds: ['u', 'other'],
    confirmationCount: 2,
    disputedByUserIds: [],
    disputeCount: 0,
  });
  store.set('monetisation_events/m', {
    uid: 'u',
    grossPence: 999,
    stripeInvoiceId: 'invoice',
  });

  const api = createAccountDeletionLifecycle({
    db,
    auth: {
      async deleteUser(uid) {
        deletedAuth.push(uid);
      },
    },
    bucket: {
      async deleteFiles({ prefix }) {
        storagePrefixes.push(prefix);
      },
    },
    fieldValue: {
      delete: () => DELETE_FIELD,
    },
    HttpsError,
    timestamp: () => now.toISOString(),
    now: () => now,
  });

  return { store, api, deletedAuth, storagePrefixes, now };
}

function request(uid, now, data = { confirmation: 'DELETE' }) {
  return {
    auth: {
      uid,
      token: { auth_time: Math.floor(now.getTime() / 1000) },
    },
    data,
  };
}

test('account deletion key is deterministic and does not expose the Firebase uid', () => {
  const key = accountDeletionKey('private-user-id');
  assert.equal(key.length, 64);
  assert(!key.includes('private-user-id'));
  assert.equal(retainedSubjectKey('private-user-id'), `deleted:${key.slice(0, 24)}`);
});

test('recent authentication is mandatory', async () => {
  const h = harness();
  const stale = request('u', new Date(h.now.getTime() - 11 * 60 * 1000));
  stale.auth.token.auth_time = Math.floor((h.now.getTime() - 11 * 60 * 1000) / 1000);
  assert.equal(isRecentAuth(stale, h.now.getTime()), false);
  await assert.rejects(
    h.api.deleteAccount(stale),
    (error) => error.code === 'failed-precondition',
  );
  await assert.rejects(
    h.api.deleteAccount(request('u', h.now, { confirmation: 'NO' })),
    (error) => error.code === 'invalid-argument',
  );
});

test('deletion removes private data, anonymises shared integrity records and retains financial evidence', async () => {
  const h = harness();
  const result = await h.api.deleteAccount(request('u', h.now));

  assert.equal(result.deleted, true);
  assert.equal(h.store.has('users/u'), false);
  assert.equal(h.store.has('users/u/personalisation/current'), false);
  assert.equal(h.store.has('public_profiles/u'), false);
  assert.equal(h.store.has('supporter_entitlements/u'), false);
  assert.equal(h.store.has('uag_ids/UAG000000001'), false);
  assert.equal(h.store.has('uag_creator_applications/a'), false);
  assert.equal(h.store.has('trading_listings/l'), false);

  const session = h.store.get('trading_sessions/s');
  assert.equal(session.traderOneUid, retainedSubjectKey('u'));
  assert.equal(session.traderOneName, 'Deleted Raider');
  assert.equal(session.traderOneEmbarkId, '');
  assert.equal(session.status, 'cancelled');

  const report = h.store.get('arc_raider_reports/r');
  assert.equal(report.targetUid, retainedSubjectKey('u'));
  assert.equal(report.targetDisplayName, 'Deleted Raider');
  assert.equal(report.incidentVerification, 'verified');

  const intel = h.store.get('arc_community_intel_reports/i');
  assert.deepEqual(intel.confirmedByUserIds, ['other']);
  assert.equal(intel.confirmationCount, 1);

  assert.equal(h.store.get('monetisation_events/m').uid, 'u');
  assert.deepEqual(h.deletedAuth, ['u']);
  assert.deepEqual(h.storagePrefixes.sort(), [
    'legal_exports/u/',
    'users/u/',
  ]);

  const tombstone = h.store.get(
    `account_deletion_tombstones/${accountDeletionKey('u')}`,
  );
  assert.equal(tombstone.status, 'complete');
  assert.equal(tombstone.subjectKey, retainedSubjectKey('u'));
});

test('deleted-account tombstone removes later server-written account documents', async () => {
  const h = harness();
  await h.api.deleteAccount(request('u', h.now));
  h.store.set('users/u', { tier: 'premium' });
  const afterRef = {
    delete: async () => h.store.delete('users/u'),
  };
  await h.api.preventResurrection({
    params: { userId: 'u' },
    data: { after: { exists: true, ref: afterRef } },
  });
  assert.equal(h.store.has('users/u'), false);

  h.store.set('supporter_entitlements/u', { uid: 'u', active: true });
  const entitlementRef = {
    delete: async () => h.store.delete('supporter_entitlements/u'),
  };
  await h.api.preventResurrection(
    {
      params: { accountUid: 'u' },
      data: { after: { exists: true, ref: entitlementRef } },
    },
    'accountUid',
  );
  assert.equal(h.store.has('supporter_entitlements/u'), false);
});
