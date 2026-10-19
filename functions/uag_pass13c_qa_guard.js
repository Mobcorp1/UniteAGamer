'use strict';

// PASS 13C: hard QA-only safety boundary. Public rollout is intentionally impossible
// under this build. Firestore rules make release controls server-owned.
const { liveListing, watchFitsListing, freshLooking, riderFits } = require('./uag_pass13_auto_matches');
const clean = (v) => String(v ?? '').trim();
const validId = (v) => typeof v === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(v);
function timeMillis(t) {
  if (t && typeof t.toMillis === 'function') return t.toMillis();
  if (t && typeof t.toDate === 'function') return t.toDate().getTime();
  if (t instanceof Date) return t.getTime();
  if (typeof t === 'string' || typeof t === 'number') return new Date(t).getTime();
  return NaN;
}
function controlValid(control, kind, now = Date.now()) {
  if (!control || control.enabled !== true || control.qaMode !== 'testers' ||
      control.publicEnabled === true || control[kind] !== true) return false;
  const ids = control.testerUids;
  if (!Array.isArray(ids) || ids.length < 2 || ids.length > 10 ||
      new Set(ids).size !== ids.length || !ids.every(validId)) return false;
  const expires = timeMillis(control.qaExpiresAt);
  return Number.isFinite(expires) && expires > now && expires <= now + 7 * 86400000;
}
function qaPairAllowed(control, leftUid, rightUid, kind, now = Date.now()) {
  return controlValid(control, kind, now) && validId(leftUid) && validId(rightUid) &&
    leftUid !== rightUid && control.testerUids.includes(leftUid) && control.testerUids.includes(rightUid);
}
function qaMemberAllowed(control, uid, kind, now = Date.now()) {
  return controlValid(control, kind, now) && validId(uid) && control.testerUids.includes(uid);
}
async function readControl(db) {
  const snap = await db.collection('uag_release_controls').doc('launch_matching').get();
  return snap.data() || {};
}
function ageVerified(data) { return data?.ageVerification?.verifiedOver18 === true; }
async function activeAccount(admin, uid) {
  try { return (await admin.auth().getUser(uid)).disabled !== true; }
  catch (e) { if (e.code === 'auth/user-not-found') return false; throw e; }
}
async function approvedUsers(db, admin, targetUid, actorUid, targetCategory, actorCategory) {
  const [target, actor, targetPrefs, actorPrefs, blockedA, blockedB, targetActive, actorActive] = await Promise.all([
    db.collection('users').doc(targetUid).get(),
    db.collection('users').doc(actorUid).get(),
    db.collection('users').doc(targetUid).collection('notification_preferences').doc('current').get(),
    db.collection('users').doc(actorUid).collection('notification_preferences').doc('current').get(),
    db.collection('uag_user_blocks').doc(`${targetUid}_${actorUid}`).get(),
    db.collection('uag_user_blocks').doc(`${actorUid}_${targetUid}`).get(),
    activeAccount(admin, targetUid), activeAccount(admin, actorUid),
  ]);
  const left = target.data(), right = actor.data();
  return targetActive && actorActive && ageVerified(left) && ageVerified(right) &&
    !blockedA.exists && !blockedB.exists && targetPrefs.data()?.[targetCategory] !== false &&
    actorPrefs.data()?.[actorCategory] !== false &&
    !(left?.blockedMatchRiderUids || []).includes(actorUid) &&
    !(right?.blockedMatchRiderUids || []).includes(targetUid);
}
// Called immediately before dispatch, not just at candidate creation. By design,
// silently fails closed on stale listing, changed consent, revoked QA gate or block.
async function canDeliver(db, admin, notification, now = Date.now()) {
  if (notification?.pass13Discovery !== true) return false;
  const type = clean(notification.type);
  const kind = type === 'watch_match' ? 'tradeAlertsEnabled' :
    type === 'matchmaking' ? 'squadAlertsEnabled' : '';
  if (!kind) return false;
  const targetUid = clean(notification.targetUid), actorUid = clean(notification.actorUid);
  const control = await readControl(db);
  if (!qaPairAllowed(control, targetUid, actorUid, kind, now)) return false;
  if (!(await approvedUsers(db, admin, targetUid, actorUid,
    type === 'watch_match' ? 'watchesAndQueues' : 'matchmaking',
    type === 'watch_match' ? 'trading' : 'matchmaking'))) return false;
  if (type === 'watch_match') {
    const watchId = clean(notification.watchId), listingId = clean(notification.listingId);
    if (!validId(watchId) || !validId(listingId)) return false;
    const [watch, listing] = await Promise.all([
      db.collection('arc_blueprint_watches').doc(watchId).get(),
      db.collection('trading_listings').doc(listingId).get(),
    ]);
    const w = watch.data(), l = listing.data();
    return !!watch.exists && !!listing.exists && w?.ownerUid === targetUid &&
      clean(l?.ownerUid || l?.userId) === actorUid && liveListing(l, now) &&
      watchFitsListing(w, l, now) && w?.notificationPreference === 'immediate';
  }
  const [target, actor] = await Promise.all([
    db.collection('arc_match_rider_profiles').doc(targetUid).get(),
    db.collection('arc_match_rider_profiles').doc(actorUid).get(),
  ]);
  const left = target.data(), right = actor.data();
  return !!target.exists && !!actor.exists && left?.uid === targetUid &&
    right?.uid === actorUid && freshLooking(left, now) && freshLooking(right, now) &&
    riderFits(left, right, now);
}
module.exports = { controlValid, qaMemberAllowed, qaPairAllowed, readControl, canDeliver, timeMillis };
