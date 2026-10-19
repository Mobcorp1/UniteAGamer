'use strict';

// UAG PASS 13: opt-in, candidate-only discovery. No trade or squad is auto-accepted.
const crypto = require('crypto');

const clean = (v) => String(v ?? '').trim();
const slug = (v) => clean(v).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const strings = (v) => Array.isArray(v) ? v.filter((x) => typeof x === 'string').map(clean).filter(Boolean) : [];
const shared = (a, b) => strings(a).some((x) => strings(b).some((y) => slug(x) === slug(y)));
const idFor = (...parts) => crypto.createHash('sha256').update(parts.join('|')).digest('hex');
const expiryMillis = (v) => v && typeof v.toMillis === 'function' ? v.toMillis() :
  (v && typeof v.toDate === 'function' ? v.toDate().getTime() : Date.parse(clean(v)));

function liveListing(listing, now = Date.now()) {
  return !!listing && listing.active === true && Number.isFinite(expiryMillis(listing.expiresAt)) &&
    expiryMillis(listing.expiresAt) > now && clean(listing.ownerUid || listing.userId).length > 0;
}

function watchFitsListing(watch, listing, now = Date.now()) {
  if (!liveListing(listing, now) || !watch || watch.active !== true ||
    watch.type !== 'blueprint' || watch.notificationsEnabled !== true ||
    watch.notificationPreference === 'muted') return false;
  if (!clean(watch.ownerUid) || clean(watch.ownerUid) === clean(listing.ownerUid || listing.userId)) return false;
  const wanted = [watch.blueprintId, watch.blueprintDisplayName].map(slug).filter(Boolean);
  const offered = [...strings(listing.offeredBlueprintNames), ...strings(listing.offeredTradeItemIds),
    ...strings(listing.offeredTradeItemNames)].map(slug);
  return wanted.some((x) => offered.includes(x));
}

// Avoid claiming a percentage or advanced proprietary client scoring on the server.
function riderFits(left, right) {
  if (!left || !right || !clean(left.uid) || !clean(right.uid) || left.uid === right.uid) return false;
  if (left.visibleInSearch === false || right.visibleInSearch === false) return false;
  if (left.lookingNow !== true || right.lookingNow !== true) return false;
  if (left.autoMatchAlertsEnabled !== true || right.autoMatchAlertsEnabled !== true) return false;
  const lPlatform = slug(left.platform), rPlatform = slug(right.platform);
  if (lPlatform && rPlatform && lPlatform !== rPlatform &&
    (left.crossplayEnabled === false || right.crossplayEnabled === false)) return false;
  if (clean(left.region) && clean(right.region) && slug(left.region) !== slug(right.region)) return false;
  const lServer = slug(left.serverPreference), rServer = slug(right.serverPreference);
  if (lServer && rServer && lServer !== 'automatic' && rServer !== 'automatic' && lServer !== rServer) return false;
  const blocked = (a, b) => strings(a.blockedMatchRiderUids).includes(b.uid);
  if (blocked(left, right) || blocked(right, left)) return false;
  return shared(left.preferredEvents, right.preferredEvents) ||
    shared(left.preferredMaps, right.preferredMaps) || shared(left.playstyles, right.playstyles);
}

const isAgeVerified = (user) => user && user.ageVerification && user.ageVerification.verifiedOver18 === true;
const noBlock = (a, bUid) => !strings(a.blockedMatchRiderUids).includes(bUid);

function buildHandlers(db, admin) {
  const firestore = admin.firestore;
  const ageCache = new Map();
  async function user(uid) {
    if (!uid) return null;
    if (!ageCache.has(uid)) ageCache.set(uid, db.collection('users').doc(uid).get().then((s) => s.data() || null));
    return ageCache.get(uid);
  }
  async function pairIsUnblocked(aUid, bUid) {
    const [a, b, ab, ba] = await Promise.all([
      user(aUid), user(bUid),
      db.collection('uag_user_blocks').doc(`${aUid}_${bUid}`).get(),
      db.collection('uag_user_blocks').doc(`${bUid}_${aUid}`).get(),
    ]);
    return !ab.exists && !ba.exists && noBlock(a, bUid) && noBlock(b, aUid);
  }
  async function notifyAllowed(uid, kind) {
    const [current, prefs] = await Promise.all([
      user(uid),
      db.collection('users').doc(uid).collection('notification_preferences').doc('current').get(),
    ]);
    return isAgeVerified(current) && prefs.data()?.[kind] !== false;
  }
  async function queue({ targetUid, actorUid, type, sourceId, listingId, route, title, body, push }) {
    const ref = db.collection('trading_notifications').doc(idFor('pass13', type, sourceId, targetUid));
    try {
      await ref.create({
        id: ref.id, targetUid, actorUid, title, body, type,
        route, deepLink: route, entityId: sourceId,
        listingId: type === 'watch_match' ? listingId : null,
        offerId: null, sessionId: null,
        broadcastPushHandled: push !== true,
        read: false, createdAt: firestore.FieldValue.serverTimestamp(),
        updatedAt: firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.code !== 6 && e.code !== 'already-exists') throw e;
    }
  }
  async function checkWatch(watchId, watch, listingId, listing) {
    if (!watchFitsListing(watch, listing)) return;
    const sellerUid = clean(listing.ownerUid || listing.userId);
    const buyerUid = clean(watch.ownerUid);
    if (!(await notifyAllowed(buyerUid, 'watchesAndQueues'))) return;
    const [buyer, seller] = await Promise.all([user(buyerUid), user(sellerUid)]);
    if (!isAgeVerified(seller) || !(await pairIsUnblocked(buyerUid, sellerUid))) return;
    // Immediate alerts are explicit. Other watch preferences remain in-app or silent;
    // time-window/digest matching must be implemented before sending scheduled pushes.
    if (watch.notificationPreference === 'digest' || watch.notificationPreference === 'favouriteRidersOnly') return;
    const push = watch.notificationPreference === 'immediate';
    await queue({ targetUid: buyerUid, actorUid: sellerUid, type: 'watch_match',
      sourceId: `${listingId}_${watchId}`, listingId, route: '/trading-hub/arc-raiders/blueprint-watches',
      title: 'UAG trade opportunity', body: 'A live listing matches your Blueprint Watch. Review before sending an offer.', push });
  }
  async function onListing(event) {
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists) return;
    const listing = snap.data();
    if (!liveListing(listing)) return;
    const watches = await db.collection('arc_blueprint_watches').limit(400).get();
    for (const watch of watches.docs) {
      await checkWatch(watch.id, watch.data(), snap.id, listing);
    }
  }
  async function onWatch(event) {
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists) return;
    const watch = snap.data();
    if (!watch || !watch.active || !watch.notificationsEnabled || watch.type !== 'blueprint') return;
    const listings = await db.collection('arc_trade_listings').limit(300).get();
    for (const listing of listings.docs) {
      await checkWatch(snap.id, watch, listing.id, listing.data());
    }
  }
  async function onRider(event) {
    const snap = event.data?.after ?? event.data;
    if (!snap?.exists) return;
    const current = snap.data();
    if (current.lookingNow !== true || current.autoMatchAlertsEnabled !== true || current.visibleInSearch === false) return;
    if (!(await notifyAllowed(snap.id, 'matchmaking'))) return;
    const profiles = await db.collection('arc_match_rider_profiles').limit(250).get();
    for (const doc of profiles.docs) {
      if (doc.id === snap.id || !riderFits(current, doc.data())) continue;
      const other = doc.data();
      if (!(await notifyAllowed(doc.id, 'matchmaking'))) continue;
      const [left, right] = await Promise.all([user(snap.id), user(doc.id)]);
      if (!isAgeVerified(left) || !isAgeVerified(right) || !(await pairIsUnblocked(snap.id, doc.id))) continue;
      const pair = [snap.id, doc.id].sort().join('_');
      for (const recipient of [{uid:snap.id, actor:doc.id}, {uid:doc.id, actor:snap.id}]) {
        await queue({ targetUid: recipient.uid, actorUid: recipient.actor, type: 'matchmaking',
          sourceId: pair, route: '/trading-hub/arc-raiders/match-a-raider',
          title: 'Potential squadmate found', body: 'A Raider is looking now with compatible game preferences. Review their profile before inviting.', push: true });
      }
    }
  }
  return { onListing, onWatch, onRider };
}

module.exports = { slug, liveListing, watchFitsListing, riderFits, buildHandlers };
