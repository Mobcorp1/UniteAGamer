const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');

admin.initializeApp();

const db = admin.firestore();

const FLEXIBLE_VALUES = new Set(['', 'flexible', 'any', 'all']);

function normalize(value) {
  return String(value || '').trim().toLowerCase();
}

function slug(value) {
  return normalize(value).replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function readWantedNames(listing) {
  const names = new Set();
  const rawNames = Array.isArray(listing.wantedBlueprintNames)
    ? listing.wantedBlueprintNames
    : [];

  rawNames.forEach((name) => {
    const normalized = normalize(name);
    if (normalized) names.add(normalized);
  });

  const wantedText = normalize(listing.wantedText);
  if (wantedText) {
    wantedText
      .split(',')
      .map((part) => normalize(part))
      .filter(Boolean)
      .forEach((part) => names.add(part));
  }

  return names;
}

function readOfferedNames(listing) {
  const names = new Set();
  const rawNames = Array.isArray(listing.offeredBlueprintNames)
    ? listing.offeredBlueprintNames
    : [];

  rawNames.forEach((name) => {
    const normalized = normalize(name);
    if (normalized) names.add(normalized);
  });

  const offeredItem = normalize(listing.offeredItem);
  if (offeredItem) names.add(offeredItem);
  return names;
}

function regionsCompatible(regionA, regionB) {
  const a = normalize(regionA);
  const b = normalize(regionB);
  if (FLEXIBLE_VALUES.has(a) || FLEXIBLE_VALUES.has(b)) return true;
  return a === b;
}

function timeToMinutes(value) {
  const match = String(value || '').match(/^(\d{1,2}):(\d{2})$/);
  if (!match) return null;
  return (Number(match[1]) * 60) + Number(match[2]);
}

function availabilityDocsCompatible(a, b) {
  const weeksA = Array.isArray(a?.weeks) ? a.weeks : [];
  const weeksB = Array.isArray(b?.weeks) ? b.weeks : [];
  if (!weeksA.length || !weeksB.length) return true;

  for (const weekA of weeksA) {
    for (const slotA of Array.isArray(weekA.slots) ? weekA.slots : []) {
      if (!slotA?.enabled) continue;
      const startA = timeToMinutes(slotA.fromTime);
      const endA = timeToMinutes(slotA.toTime);
      if (startA == null || endA == null) continue;

      for (const weekB of weeksB) {
        for (const slotB of Array.isArray(weekB.slots) ? weekB.slots : []) {
          if (!slotB?.enabled || slotA.dayKey !== slotB.dayKey) continue;
          const startB = timeToMinutes(slotB.fromTime);
          const endB = timeToMinutes(slotB.toTime);
          if (startB == null || endB == null) continue;
          if (Math.min(endA, endB) > Math.max(startA, startB)) {
            return true;
          }
        }
      }
    }
  }

  return false;
}

function playWindowsOverlap(windowA, windowB) {
  const a = normalize(windowA);
  const b = normalize(windowB);
  if (FLEXIBLE_VALUES.has(a) || FLEXIBLE_VALUES.has(b)) return true;
  if (a === b) return true;

  const overlapMap = {
    afternoons: new Set(['evenings', 'weekends']),
    evenings: new Set(['afternoons', 'late-night', 'weekends']),
    'late night': new Set(['evenings', 'weekends']),
    latenight: new Set(['evenings', 'weekends']),
    weekends: new Set(['afternoons', 'evenings', 'late-night', 'latenight']),
  };

  return overlapMap[a]?.has(b) || overlapMap[b]?.has(a) || false;
}

function buildNotificationId(type, actorUid, targetUid, listingId, blueprintName) {
  return [type, actorUid, targetUid, listingId, slug(blueprintName)].join('__');
}

async function upsertTradingNotification({
  id,
  actorUid,
  targetUid,
  title,
  body,
  type,
  listingId = '',
  offerId = '',
  sessionId = '',
}) {
  if (!actorUid || !targetUid || actorUid === targetUid) return;

  await db.collection('trading_notifications').doc(id).set({
    id,
    actorUid,
    targetUid,
    title,
    body,
    type,
    listingId,
    offerId,
    sessionId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

exports.sendTradingNotificationPush = onDocumentCreated(
  'trading_notifications/{notificationId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data() || {};
    const targetUid = data.targetUid;
    if (!targetUid) return;

    const tokensSnap = await db
      .collection('users')
      .doc(targetUid)
      .collection('notification_tokens')
      .get();

    const tokens = tokensSnap.docs
      .map((doc) => doc.id)
      .filter((token) => typeof token === 'string' && token.length > 0);

    if (!tokens.length) return;

    const message = {
      tokens,
      notification: {
        title: data.title || 'Trading update',
        body: data.body || 'Open the app for details.',
      },
      data: {
        type: data.type || '',
        listingId: data.listingId || '',
        offerId: data.offerId || '',
        sessionId: data.sessionId || '',
        title: data.title || 'Trading update',
        body: data.body || 'Open the app for details.',
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      if (!result.success) {
        const code = result.error && result.error.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          invalidTokens.push(tokens[index]);
        }
      }
    });

    await Promise.all(
      invalidTokens.map((token) =>
        db
          .collection('users')
          .doc(targetUid)
          .collection('notification_tokens')
          .doc(token)
          .delete()
      )
    );
  }
);

exports.createDuplicateMatchNotifications = onDocumentWritten(
  'users/{uid}/arc_blueprints/{blueprintId}',
  async (event) => {
    const after = event.data && event.data.after ? event.data.after.data() : null;
    const before = event.data && event.data.before ? event.data.before.data() : null;
    const actorUid = event.params.uid;
    if (!after || !actorUid) return;

    const nextDupes = Number(after.dupesOwned || 0);
    const prevDupes = Number(before?.dupesOwned || 0);
    if (nextDupes <= 0 || nextDupes === prevDupes) return;

    const blueprintName = normalize(after.blueprintName || after.name || after.blueprintId || event.params.blueprintId);
    if (!blueprintName) return;

    const actorListingsSnap = await db
      .collection('trading_listings')
      .where('ownerUid', '==', actorUid)
      .where('active', '==', true)
      .get();

    const actorListings = actorListingsSnap.docs.map((doc) => doc.data());
    const actorAvailabilitySnap = await db.collection('users').doc(actorUid).collection('trading_activity').doc('availability').get();
    const actorAvailability = actorAvailabilitySnap.data() || null;

    const targetListingsSnap = await db
      .collection('trading_listings')
      .where('active', '==', true)
      .get();

    const writes = [];

    for (const doc of targetListingsSnap.docs) {
      const listing = doc.data();
      const targetUid = listing.ownerUid;
      if (!targetUid || targetUid === actorUid) continue;

      const wantedNames = readWantedNames(listing);
      if (!wantedNames.has(blueprintName)) continue;

      const targetAvailabilitySnap = await db.collection('users').doc(targetUid).collection('trading_activity').doc('availability').get();
      const targetAvailability = targetAvailabilitySnap.data() || null;

      const compatibleActorListing = actorListings.find((actorListing) => {
        if (!regionsCompatible(actorListing.region, listing.region)) return false;
        if (!playWindowsOverlap(actorListing.playWindow, listing.playWindow)) return false;
        if (!availabilityDocsCompatible(actorAvailability, targetAvailability)) return false;
        return true;
      });

      if (!compatibleActorListing) continue;

      const targetOffered = readOfferedNames(listing);
      const actorWanted = readWantedNames(compatibleActorListing);
      const mutual = [...targetOffered].some((name) => actorWanted.has(name));

      const type = mutual ? 'mutualMatch' : 'duplicateMatch';
      const title = mutual ? 'Mutual trade match found' : 'New duplicate match found';
      const body = mutual
        ? 'A trader has a duplicate you need and their listing lines up with your region and play window.'
        : 'A trader has a duplicate you need and their listing lines up with your region and play window.';

      writes.push(
        upsertTradingNotification({
          id: buildNotificationId(type, actorUid, targetUid, doc.id, blueprintName),
          actorUid,
          targetUid,
          title,
          body,
          type,
          listingId: doc.id,
        })
      );

      if (mutual) {
        writes.push(
          upsertTradingNotification({
            id: buildNotificationId(type, targetUid, actorUid, compatibleActorListing.id || '', blueprintName),
            actorUid: targetUid,
            targetUid: actorUid,
            title,
            body: 'One of your active listings now lines up with a trader who has what you need and wants something you offer.',
            type,
            listingId: compatibleActorListing.id || '',
          })
        );
      }
    }

    await Promise.all(writes);
  }
);
