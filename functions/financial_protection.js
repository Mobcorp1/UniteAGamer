'use strict';

const { createHash } = require('node:crypto');
const CONTROL_PATH = 'app_config/financial_protection';
const UNAVAILABLE = 'This optional service is temporarily unavailable. Please try again later.';

// Best-effort per-instance shield for public HTTP calls; bounded memory and no
// database writes. Distributed clients can bypass it; it is not a global quota.
function createLocalRateLimit({ maximum = 60, windowMs = 60000, capacity = 4096, now = Date.now } = {}) {
  const windows = new Map();
  return identity => {
    const at = now();
    const key = createHash('sha256').update(String(identity)).digest('hex');
    let entry = windows.get(key);
    if (!entry || at >= entry.until) {
      if (windows.size >= capacity) {
        for (const [id, item] of windows) if (at >= item.until) windows.delete(id);
        if (!windows.has(key) && windows.size >= capacity) return false;
      }
      entry = { until: at + windowMs, count: 0 };
      windows.set(key, entry);
    }
    return ++entry.count <= maximum;
  };
}

// A bounded cache coalesces concurrent checks, including failed reads. No listener.
// Other warm instances observe changes within five seconds; in-flight work is not revoked.
function createFinancialProtection({ db, auth, HttpsError, timestamp, now = Date.now }) {
  let cached, expiresAt = 0, loading;
  const fail = (code, message) => { throw new HttpsError(code, message); };
  async function restricted() {
    if (cached !== undefined && now() < expiresAt) return cached;
    if (!loading) {
      loading = (async () => {
        try {
          const snapshot = await db.doc(CONTROL_PATH).get();
          cached = snapshot.exists ? snapshot.data()?.active !== false : false;
        } catch (_) {
          cached = true;
        }
        expiresAt = now() + 5000;
        return cached;
      })().finally(() => { loading = undefined; });
    }
    return loading;
  }
  async function assertAvailable() {
    if (await restricted()) fail('unavailable', UNAVAILABLE);
  }
  // One reusable document per account and operation, not one per invocation.
  // Rejected attempts do not write. This limits expensive work, not invocation billing.
  async function consume(uid, operation, maximum, windowMs = 60000) {
    const digest = createHash('sha256').update(`${uid}\0${operation}`).digest('hex');
    const ref = db.collection('financial_operation_limits').doc(digest);
    await db.runTransaction(async tx => {
      const data = (await tx.get(ref)).data() || {};
      const at = now();
      const current = Number.isFinite(data.windowStart) && at >= data.windowStart && at - data.windowStart < windowMs;
      const count = current ? Number(data.count || 0) : 0;
      if (count >= maximum) fail('resource-exhausted', 'Too many requests. Please wait a minute before trying again.');
      tx.set(ref, { count: count + 1, windowStart: current ? data.windowStart : at, updatedAt: timestamp() });
    });
  }
  function protectCallable(operation, maximum, handler) {
    return async request => {
      if (!request.auth?.uid) fail('unauthenticated', 'Sign in required.');
      await assertAvailable();
      await consume(request.auth.uid, operation, maximum);
      return handler(request);
    };
  }
  async function setRestriction(request) {
    const uid = request.auth?.uid;
    if (!uid) fail('unauthenticated', 'Sign in required.');
    const data = request.data || {};
    if (typeof data.active !== 'boolean' || typeof data.reason !== 'string' ||
        data.reason.trim().length < 10 || data.reason.length > 500 ||
        !Number.isSafeInteger(data.expectedRevision) || data.expectedRevision < 0 ||
        typeof data.requestId !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/.test(data.requestId)) {
      fail('invalid-argument', 'Provide active, a reason (10–500 characters), expectedRevision and a unique requestId (16–80 safe characters).');
    }
    const account = await auth.getUser(uid);
    if (account.disabled) fail('permission-denied', 'Administrator access required.');
    const control = db.doc(CONTROL_PATH);
    const audit = db.collection('financial_protection_audit').doc(data.requestId);
    const result = await db.runTransaction(async tx => {
      const [user, previous, receipt] = await Promise.all([
        tx.get(db.collection('users').doc(uid)), tx.get(control), tx.get(audit),
      ]);
      const role = user.data() || {};
      if (role.isAdmin !== true && role.isDev !== true) fail('permission-denied', 'Administrator access required.');
      if (receipt.exists) {
        const prior = receipt.data();
        if (prior.actorUid !== uid || prior.active !== data.active || prior.reason !== data.reason.trim() ||
            prior.expectedRevision !== data.expectedRevision) fail('already-exists', 'Request ID already used.');
        return { active: prior.active, revision: prior.revision };
      }
      const revision = previous.data()?.revision || 0;
      if (revision !== data.expectedRevision) fail('aborted', 'Control changed. Read its latest revision and retry.');
      const next = { active: data.active, revision: revision + 1, reason: data.reason.trim(),
        updatedBy: uid, updatedAt: timestamp() };
      tx.set(control, next);
      tx.create(audit, { ...next, actorUid: uid, expectedRevision: revision,
        previousActive: previous.exists ? previous.data()?.active !== false : false });
      return { active: next.active, revision: next.revision };
    });
    // Wait for any older read to finish before invalidating it.
    if (loading) await loading;
    cached = undefined;
    expiresAt = 0;
    return result;
  }
  return { restricted, assertAvailable, consume, protectCallable, setRestriction };
}

module.exports = { createFinancialProtection, createLocalRateLimit, CONTROL_PATH, UNAVAILABLE };
