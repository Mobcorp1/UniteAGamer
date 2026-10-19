'use strict';

// PASS 13B: server-owned, candidate-only discovery. No automatic trade acceptance.
const crypto = require('crypto');
const clean = (value) => String(value ?? '').trim();
const slug = (value) => clean(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const strings = (value) => Array.isArray(value) ? value.filter((v) => typeof v === 'string').map(clean).filter(Boolean) : [];
const shared = (a, b) => strings(a).some((x) => strings(b).some((y) => slug(x) === slug(y)));
const idFor = (...parts) => crypto.createHash('sha256').update(JSON.stringify(parts)).digest('hex');
const millis = (value) => {
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value && typeof value.toDate === 'function') return value.toDate().getTime();
  if (value instanceof Date) return value.getTime();
  return typeof value === 'string' ? Date.parse(value) : NaN;
};
const ageVerified = (user) => user?.ageVerification?.verifiedOver18 === true;
const noBlockField = (user, uid) => !strings(user?.blockedMatchRiderUids).includes(uid);
const prefAllows = (preferences, kind) => preferences?.[kind] !== false;

function liveListing(listing, now = Date.now()) {
  return !!listing && listing.active === true && Number.isFinite(millis(listing.expiresAt)) &&
    millis(listing.expiresAt) > now && !!clean(listing.ownerUid || listing.userId);
}
function watchFitsListing(watch, listing, now = Date.now()) {
  if (!liveListing(listing, now) || !watch || watch.active !== true ||
      watch.type !== 'blueprint' || watch.notificationsEnabled !== true ||
      watch.notificationPreference === 'muted' || !clean(watch.ownerUid) ||
      clean(watch.ownerUid) === clean(listing.ownerUid || listing.userId)) return false;
  const wanted = [watch.blueprintId, watch.blueprintDisplayName].map(slug).filter(Boolean);
  const offered = [...strings(listing.offeredBlueprintNames), ...strings(listing.offeredTradeItemIds),
    ...strings(listing.offeredTradeItemNames)].map(slug);
  return wanted.some((needle) => offered.includes(needle));
}
function freshLooking(profile, now = Date.now(), maxAgeMs = 6 * 60 * 60 * 1000) {
  const lastChanged = millis(profile?.updatedAt);
  return profile?.lookingNow === true && profile?.autoMatchAlertsEnabled === true &&
    profile?.visibleInSearch !== false && Number.isFinite(lastChanged) &&
    lastChanged <= now && now - lastChanged <= maxAgeMs;
}
function riderFits(left, right, now = Date.now()) {
  if (!left || !right || !clean(left.uid) || !clean(right.uid) || left.uid === right.uid) return false;
  if (!freshLooking(left, now) || !freshLooking(right, now)) return false;
  const leftPlatform = slug(left.platform), rightPlatform = slug(right.platform);
  if (leftPlatform && rightPlatform && leftPlatform !== rightPlatform &&
      (left.crossplayEnabled === false || right.crossplayEnabled === false)) return false;
  const leftRegion = slug(left.region), rightRegion = slug(right.region);
  if (leftRegion && rightRegion && leftRegion !== rightRegion) return false;
  const leftServer = slug(left.serverPreference), rightServer = slug(right.serverPreference);
  if (leftServer && rightServer && leftServer !== 'automatic' && rightServer !== 'automatic' && leftServer !== rightServer) return false;
  if (!noBlockField(left, right.uid) || !noBlockField(right, left.uid)) return false;
  const bothHaveEvents = strings(left.preferredEvents).length && strings(right.preferredEvents).length;
  if (bothHaveEvents && !shared(left.preferredEvents, right.preferredEvents)) return false;
  if (strings(left.comms).length && strings(right.comms).length && !shared(left.comms, right.comms) &&
      !strings(left.comms).includes('Flexible') && !strings(right.comms).includes('Flexible')) return false;
  return shared(left.preferredEvents, right.preferredEvents) ||
    shared(left.preferredMaps, right.preferredMaps) || shared(left.playstyles, right.playstyles);
}

// Paging protects early-launch discovery from arbitrary first-page omissions.
// A hard cap deliberately fails visibly instead of claiming a complete search.
async function readCandidates(db, path, maxDocs = 3000) {
  const perPage = 250;
  const items = [];
  let previous = null;
  for (;;) {
    let q = db.collection(path).orderBy('__name__').limit(perPage);
    if (previous) q = q.startAfter(previous);
    const page = await q.get();
    items.push(...page.docs);
    if (items.length > maxDocs) throw new Error(`PASS13B_DISCOVERY_CAP_EXCEEDED:${path}`);
    if (page.size < perPage) return items;
    previous = page.docs[page.docs.length - 1];
  }
}
function buildHandlers(db, admin) {
  const timestamp = () => admin.firestore.FieldValue.serverTimestamp();
  const users = new Map();
  const prefCache = new Map();
  const authCache = new Map();
  const getUser = async (uid) => {
    if (!users.has(uid)) users.set(uid, db.collection('users').doc(uid).get().then((doc) => doc.data() || null));
    return users.get(uid);
  };
  const getPreferences = async (uid) => {
    if (!prefCache.has(uid)) prefCache.set(uid, db.collection('users').doc(uid)
      .collection('notification_preferences').doc('current').get().then((doc) => doc.data() || null));
    return prefCache.get(uid);
  };
  const isActiveAccount = async (uid) => {
    if (!authCache.has(uid)) authCache.set(uid, admin.auth().getUser(uid)
      .then((record) => !record.disabled).catch((error) => {
        if (error.code === 'auth/user-not-found') return false;
        throw error;
      }));
    return authCache.get(uid);
  };
  async function allowed(uid, kind) {
    const [user, prefs, active] = await Promise.all([getUser(uid), getPreferences(uid), isActiveAccount(uid)]);
    return !!active && ageVerified(user) && prefAllows(prefs, kind);
  }
  async function unblocked(aUid, bUid) {
    const [a, b, first, second] = await Promise.all([
      getUser(aUid), getUser(bUid),
      db.collection('uag_user_blocks').doc(`${aUid}_${bUid}`).get(),
      db.collection('uag_user_blocks').doc(`${bUid}_${aUid}`).get(),
    ]);
    return !first.exists && !second.exists && noBlockField(a, bUid) && noBlockField(b, aUid);
  }
  async function enabled(kind) {
    const doc = await db.collection('uag_release_controls').doc('launch_matching').get();
    const data = doc.data() || {};
    return data.enabled === true && data[kind] === true;
  }
  async function queue({ targetUid, actorUid, type, sourceId, listingId = null, watchId = null, route, title, body, push }) {
    const ref = db.collection('trading_notifications').doc(idFor('pass13b', type, sourceId, targetUid));
    try {
      await ref.create({
        id: ref.id, targetUid, actorUid, title, body, type,
        route, deepLink: route, entityId: sourceId, listingId, watchId,
        offerId: null, sessionId: null, broadcastPushHandled: push !== true,
        read: false, createdAt: timestamp(), updatedAt: timestamp(),
      });
    } catch (error) {
      if (error.code !== 6 && error.code !== 'already-exists') throw error;
    }
  }
  async function checkWatch(watchId, watch, listingId, listing) {
    if (!watchFitsListing(watch, listing)) return;
    const sellerUid = clean(listing.ownerUid || listing.userId);
    const buyerUid = clean(watch.ownerUid);
    const preference = clean(watch.notificationPreference);
    if (preference === 'digest' || preference === 'favouriteRidersOnly') return;
    if (!(await allowed(buyerUid, 'watchesAndQueues')) || !(await allowed(sellerUid, 'trading')) ||
        !(await unblocked(buyerUid, sellerUid))) return;
    // A listing is a potential opportunity only. Never auto-propose or book a trade.
    // A non-immediate Watch is in-app only until availability/digest policies exist.
    const push = preference === 'immediate';
    await queue({ targetUid: buyerUid, actorUid: sellerUid, type: 'watch_match',
      sourceId: `${listingId}:${watchId}`, listingId, watchId,
      route: '/trading-hub/arc-raiders/blueprint-watches',
      title: 'Potential Blueprint trade',
      body: 'An active offer matches your Blueprint Watch. Check the terms before responding.', push });
  }
  async function onListing(event) {
    if (!(await enabled('tradeAlertsEnabled'))) return;
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists || !liveListing(snap.data())) return;
    for (const watch of await readCandidates(db, 'arc_blueprint_watches')) {
      await checkWatch(watch.id, watch.data(), snap.id, snap.data());
    }
  }
  async function onWatch(event) {
    if (!(await enabled('tradeAlertsEnabled'))) return;
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists || snap.data()?.type !== 'blueprint') return;
    for (const listing of await readCandidates(db, 'trading_listings')) {
      await checkWatch(snap.id, snap.data(), listing.id, listing.data());
    }
  }
  async function onRider(event) {
    if (!(await enabled('squadAlertsEnabled'))) return;
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists) return;
    const current = snap.data();
    const now = Date.now();
    // Only run on the current profile's opt-in transition/fresh save.
    if (!freshLooking(current, now) || !(await allowed(snap.id, 'matchmaking'))) return;
    for (const candidate of await readCandidates(db, 'arc_match_rider_profiles')) {
      if (candidate.id === snap.id) continue;
      const other = candidate.data();
      // Explicit document identity is authoritative; never trust an injected UID.
      if (clean(current.uid) !== snap.id || clean(other.uid) !== candidate.id ||
          !riderFits(current, other, now)) continue;
      if (!(await allowed(candidate.id, 'matchmaking')) || !(await unblocked(snap.id, candidate.id))) continue;
      const pair = [snap.id, candidate.id].sort();
      // One alert per pair per 6-hour window; both profiles must remain fresh.
      const windowId = String(Math.floor(now / (6 * 60 * 60 * 1000)));
      for (const recipient of [{uid: pair[0], actor: pair[1]}, {uid: pair[1], actor: pair[0]}]) {
        await queue({ targetUid: recipient.uid, actorUid: recipient.actor, type: 'matchmaking',
          sourceId: `${pair.join(':')}:${windowId}`, route: '/trading-hub/arc-raiders/match-a-raider',
          title: 'Potential squadmate found',
          body: 'A compatible Raider is looking for a squad. Review their profile before inviting.', push: true });
      }
    }
  }
  return { onListing, onWatch, onRider, enabled, allowed, unblocked };
}
module.exports = { slug, millis, liveListing, watchFitsListing, freshLooking, riderFits, readCandidates, buildHandlers };
