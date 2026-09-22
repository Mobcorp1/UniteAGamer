'use strict';

const { createHash } = require('node:crypto');

const RECENT_AUTH_MAX_AGE_SECONDS = 10 * 60;
const QUERY_BATCH_SIZE = 200;
const DELETED_RAIDER_LABEL = 'Deleted Raider';

function accountDeletionKey(uid) {
  return createHash('sha256')
    .update(`uag-account-deletion:${String(uid || '').trim()}`)
    .digest('hex');
}

function retainedSubjectKey(uid) {
  return `deleted:${accountDeletionKey(uid).slice(0, 24)}`;
}

function isRecentAuth(request, nowMillis = Date.now()) {
  const authTime = Number(request?.auth?.token?.auth_time || 0);
  if (!Number.isFinite(authTime) || authTime <= 0) return false;
  const ageSeconds = Math.max(0, Math.floor(nowMillis / 1000) - authTime);
  return ageSeconds <= RECENT_AUTH_MAX_AGE_SECONDS;
}

const DIRECT_PRIVATE_DOCS = Object.freeze([
  'public_profiles',
  'arc_match_rider_profiles',
  'arc_trade_offer_preferences',
  'arc_trader_profiles',
  'arc_trader_away',
  'arc_trader_availability',
  'arc_equipped_cosmetics',
  'arc_operation_progress',
  'arc_operation_telemetry',
  'arc_rewards_inventory',
  'uag_referral_reward_lockers',
  'uag_commercial_recognition',
  'uag_voice_preferences',
  'supporter_entitlements',
]);

const PRIVATE_QUERY_DELETIONS = Object.freeze([
  ['arc_trade_listings', 'userId'],
  ['trading_listings', 'ownerUid'],
  ['arc_trade_preparations', 'userId'],
  ['arc_blueprint_watches', 'ownerUid'],
  ['arc_trade_listing_queue', 'ownerUid'],
  ['arc_favourite_riders', 'ownerUid'],
  ['arc_favourite_riders', 'riderUid'],
  ['arc_match_rider_invites', 'senderUid'],
  ['arc_match_rider_invites', 'recipientUid'],
  ['trading_notifications', 'targetUid'],
  ['trading_notifications', 'actorUid'],
  ['notification_tokens', 'userId'],
  ['notification_devices', 'userId'],
  ['notification_preferences', 'userId'],
  ['uag_notification_schedules', 'userId'],
  ['uag_notification_schedules', 'targetUid'],
  ['uag_notification_schedules', 'actorUid'],
  ['notification_delivery_reports', 'userId'],
  ['notification_delivery_reports', 'targetUid'],
  ['beta_feedback', 'uid'],
  ['uag_message_outbox', 'senderUid'],
  ['uag_message_outbox', 'recipientUid'],
  ['uag_messages', 'senderUid'],
  ['uag_messages', 'recipientUid'],
  ['uag_user_blocks', 'blockerUid'],
  ['uag_user_blocks', 'blockedUid'],
  ['uag_image_import_sessions', 'uid'],
  ['uag_age_verification_requests', 'uid'],
  ['uag_referral_reward_activation_requests', 'uid'],
  ['arc_raid_routes', 'ownerUid'],
  ['arc_raid_routes', 'uid'],
  ['arc_raid_routes', 'userId'],
  ['dose_tasks', 'uid'],
  ['dose_tasks', 'userId'],
  ['arc_saved_loadouts', 'ownerUid'],
  ['arc_saved_loadouts', 'uid'],
  ['arc_saved_loadouts', 'userId'],
  ['arc_blueprint_targets', 'ownerUid'],
  ['arc_blueprint_targets', 'uid'],
  ['arc_blueprint_targets', 'userId'],
  ['arc_scrappy_states', 'ownerUid'],
  ['arc_scrappy_states', 'uid'],
  ['arc_scrappy_states', 'userId'],
  ['arc_quest_progress', 'uid'],
  ['arc_quest_progress', 'userId'],
  ['arc_bench_progress', 'uid'],
  ['arc_bench_progress', 'userId'],
  ['arc_scrappy_progress', 'uid'],
  ['arc_scrappy_progress', 'userId'],
  ['arc_season_state', 'uid'],
  ['arc_season_state', 'userId'],
  ['arc_season_history', 'uid'],
  ['arc_season_history', 'userId'],
  ['arc_item_protections', 'uid'],
  ['arc_item_protections', 'userId'],
  ['arc_item_recommendation_logs', 'uid'],
  ['arc_item_recommendation_logs', 'userId'],
  ['referral_codes', 'ownerUid'],
  ['uag_community_referral_codes', 'ownerUid'],
  ['uag_ids', 'uid'],
  ['uag_creator_applications', 'uid'],
  ['uag_creator_campaign_code_requests', 'uid'],
]);

const RETAINED_CATEGORIES = Object.freeze([
  'verified trust, moderation and dispute evidence',
  'legal and policy acceptance records',
  'billing, tax, payout and anti-fraud records where retention is required',
]);

function createAccountDeletionLifecycle({
  db,
  auth,
  bucket,
  fieldValue,
  HttpsError,
  timestamp,
  now = () => new Date(),
}) {
  const fail = (code, message) => {
    throw new HttpsError(code, message);
  };

  const deletedValue = () =>
    fieldValue && typeof fieldValue.delete === 'function'
      ? fieldValue.delete()
      : null;

  async function deleteDocumentTree(ref) {
    const children =
      typeof ref.listCollections === 'function' ? await ref.listCollections() : [];
    for (const collection of children) {
      await deleteCollectionTree(collection);
    }
    await ref.delete();
  }

  async function deleteCollectionTree(collection) {
    while (true) {
      const snapshot = await collection.limit(QUERY_BATCH_SIZE).get();
      if (snapshot.empty || snapshot.docs.length === 0) return;
      for (const doc of snapshot.docs) {
        await deleteDocumentTree(doc.ref);
      }
      if (snapshot.docs.length < QUERY_BATCH_SIZE) return;
    }
  }

  async function deleteWhere(collectionName, field, value) {
    let count = 0;
    while (true) {
      const snapshot = await db
        .collection(collectionName)
        .where(field, '==', value)
        .limit(QUERY_BATCH_SIZE)
        .get();
      if (snapshot.empty || snapshot.docs.length === 0) return count;
      for (const doc of snapshot.docs) {
        await deleteDocumentTree(doc.ref);
        count += 1;
      }
      if (snapshot.docs.length < QUERY_BATCH_SIZE) return count;
    }
  }

  async function mutateWhere(collectionName, field, value, mutation) {
    let count = 0;
    while (true) {
      const snapshot = await db
        .collection(collectionName)
        .where(field, '==', value)
        .limit(QUERY_BATCH_SIZE)
        .get();
      if (snapshot.empty || snapshot.docs.length === 0) return count;
      for (const doc of snapshot.docs) {
        const patch = mutation(doc.data() || {}, doc);
        if (patch && Object.keys(patch).length > 0) {
          await doc.ref.set(patch, { merge: true });
        }
        count += 1;
      }
      if (snapshot.docs.length < QUERY_BATCH_SIZE) return count;
    }
  }

  async function mutateArrayContains(collectionName, field, uid, mutation) {
    let count = 0;
    while (true) {
      const snapshot = await db
        .collection(collectionName)
        .where(field, 'array-contains', uid)
        .limit(QUERY_BATCH_SIZE)
        .get();
      if (snapshot.empty || snapshot.docs.length === 0) return count;
      for (const doc of snapshot.docs) {
        const patch = mutation(doc.data() || {}, doc);
        if (patch && Object.keys(patch).length > 0) {
          await doc.ref.set(patch, { merge: true });
        }
        count += 1;
      }
      if (snapshot.docs.length < QUERY_BATCH_SIZE) return count;
    }
  }

  async function deleteCollectionGroupWhere(groupName, field, uid) {
    if (typeof db.collectionGroup !== 'function') return 0;
    let count = 0;
    while (true) {
      const snapshot = await db
        .collectionGroup(groupName)
        .where(field, '==', uid)
        .limit(QUERY_BATCH_SIZE)
        .get();
      if (snapshot.empty || snapshot.docs.length === 0) return count;
      for (const doc of snapshot.docs) {
        await doc.ref.delete();
        count += 1;
      }
      if (snapshot.docs.length < QUERY_BATCH_SIZE) return count;
    }
  }

  function deletedIdentityPatch(extra = {}) {
    return {
      accountDeleted: true,
      accountDeletedAt: timestamp(),
      ...extra,
    };
  }

  function terminalTradeStatus(status) {
    return ['completed', 'noShow', 'betrayal', 'cancelled'].includes(
      String(status || ''),
    );
  }

  async function deleteAccount(request) {
    const uid = String(request?.auth?.uid || '').trim();
    if (!uid) fail('unauthenticated', 'Sign in before deleting your account.');
    if (request?.data?.confirmation !== 'DELETE') {
      fail('invalid-argument', 'Type DELETE to confirm permanent account deletion.');
    }
    if (!isRecentAuth(request, now().getTime())) {
      fail(
        'failed-precondition',
        'Confirm your password again before deleting your account.',
      );
    }

    const subjectKey = retainedSubjectKey(uid);
    const tombstoneRef = db
      .collection('account_deletion_tombstones')
      .doc(accountDeletionKey(uid));
    const existingTombstone = await tombstoneRef.get();
    const existing = existingTombstone.exists
      ? existingTombstone.data() || {}
      : {};

    await tombstoneRef.set(
      {
        subjectKey,
        status: 'deleting',
        requestedAt: existing.requestedAt || timestamp(),
        updatedAt: timestamp(),
        retainedCategories: RETAINED_CATEGORIES,
      },
      { merge: true },
    );

    const counts = {
      directDocuments: 0,
      privateRecords: 0,
      anonymisedRecords: 0,
      communityVotes: 0,
      storagePrefixes: 0,
    };

    // Remove public/private account surfaces and all nested user-owned data.
    for (const collectionName of DIRECT_PRIVATE_DOCS) {
      await deleteDocumentTree(db.collection(collectionName).doc(uid));
      counts.directDocuments += 1;
    }

    for (const [collectionName, field] of PRIVATE_QUERY_DELETIONS) {
      counts.privateRecords += await deleteWhere(collectionName, field, uid);
    }

    // Legacy/community Blueprint sightings keep only structured, non-identifying
    // intelligence. Free-text notes and the account identifier are removed.
    counts.anonymisedRecords += await mutateWhere(
      'arc_blueprint_drop_reports',
      'userId',
      uid,
      () =>
        deletedIdentityPatch({
          userId: subjectKey,
          notes: '',
          displayName: deletedValue(),
          reporterName: deletedValue(),
        }),
    );

    counts.anonymisedRecords += await mutateWhere(
      'arc_community_intel_reports',
      'reporterUid',
      uid,
      () =>
        deletedIdentityPatch({
          reporterUid: subjectKey,
          notes: '',
        }),
    );

    for (const field of ['confirmedByUserIds', 'disputedByUserIds']) {
      counts.anonymisedRecords += await mutateArrayContains(
        'arc_community_intel_reports',
        field,
        uid,
        (data) => {
          const next = Array.isArray(data[field])
            ? data[field].filter((value) => value !== uid)
            : [];
          const countField =
            field === 'confirmedByUserIds' ? 'confirmationCount' : 'disputeCount';
          return {
            [field]: next,
            [countField]: next.length,
            updatedAt: timestamp(),
          };
        },
      );
    }

    // Community suggestions may remain as anonymous product ideas.
    counts.anonymisedRecords += await mutateWhere(
      'uag_community_suggestions',
      'uid',
      uid,
      () =>
        deletedIdentityPatch({
          uid: subjectKey,
          displayName: DELETED_RAIDER_LABEL,
          authorName: DELETED_RAIDER_LABEL,
        }),
    );
    counts.communityVotes += await deleteCollectionGroupWhere('votes', 'uid', uid);

    // Wall of Legends recognition is not left publicly identifying after an
    // account deletion. The historical entry is hidden and de-identified.
    for (const field of ['profileUid', 'uid']) {
      counts.anonymisedRecords += await mutateWhere(
        'wall_of_legends',
        field,
        uid,
        () =>
          deletedIdentityPatch({
            profileUid: subjectKey,
            uid: deletedValue(),
            uagId: '',
            displayName: DELETED_RAIDER_LABEL,
            publicSocialLinks: [],
            approved: false,
          }),
      );
    }

    // Shared trading history is retained only to preserve the counterparty's
    // history, dispute context and anti-abuse integrity. Live/actionable data is
    // cancelled and direct game/profile identifiers are removed.
    counts.anonymisedRecords += await mutateWhere(
      'trading_offers',
      'senderUid',
      uid,
      (data) =>
        deletedIdentityPatch({
          senderUid: subjectKey,
          senderName: DELETED_RAIDER_LABEL,
          senderGamerTag: '',
          senderPlatform: '',
          note: '',
          status: data.status === 'pending' ? 'cancelled' : data.status,
        }),
    );
    counts.anonymisedRecords += await mutateWhere(
      'trading_offers',
      'receiverUid',
      uid,
      (data) =>
        deletedIdentityPatch({
          receiverUid: subjectKey,
          status: data.status === 'pending' ? 'cancelled' : data.status,
        }),
    );

    counts.anonymisedRecords += await mutateWhere(
      'trading_sessions',
      'traderOneUid',
      uid,
      (data) =>
        deletedIdentityPatch({
          traderOneUid: subjectKey,
          traderOneName: DELETED_RAIDER_LABEL,
          traderOneEmbarkId: '',
          traderOneSharedEmbarkId: false,
          status: terminalTradeStatus(data.status) ? data.status : 'cancelled',
          firstDropUid: data.firstDropUid === uid ? subjectKey : data.firstDropUid,
          bookingProposedByUid:
            data.bookingProposedByUid === uid ? subjectKey : data.bookingProposedByUid,
        }),
    );
    counts.anonymisedRecords += await mutateWhere(
      'trading_sessions',
      'traderTwoUid',
      uid,
      (data) =>
        deletedIdentityPatch({
          traderTwoUid: subjectKey,
          traderTwoName: DELETED_RAIDER_LABEL,
          traderTwoEmbarkId: '',
          traderTwoSharedEmbarkId: false,
          status: terminalTradeStatus(data.status) ? data.status : 'cancelled',
          firstDropUid: data.firstDropUid === uid ? subjectKey : data.firstDropUid,
          bookingProposedByUid:
            data.bookingProposedByUid === uid ? subjectKey : data.bookingProposedByUid,
        }),
    );

    // Trust/safety cases are retained because deleting them could erase verified
    // abuse, evidence, moderation history or an active dispute. Only the public
    // identity surface is minimised; the role linkage becomes a deletion key.
    const trustRoleSpecs = [
      ['arc_raider_reports', 'reporterUid', 'reporterUid', 'reporterDisplayName'],
      ['arc_raider_reports', 'targetUid', 'targetUid', 'targetDisplayName'],
      ['arc_raider_contracts', 'reporterUid', 'reporterUid', 'reporterDisplayName'],
      ['arc_raider_contracts', 'targetUid', 'targetUid', 'targetDisplayName'],
      ['arc_raider_contracts', 'hunterUid', 'hunterUid', 'hunterDisplayName'],
      ['arc_contract_challenges', 'reporterUid', 'reporterUid', 'reporterDisplayName'],
      ['arc_contract_challenges', 'targetUid', 'targetUid', 'targetDisplayName'],
      ['arc_contract_challenges', 'hunterUid', 'hunterUid', 'hunterDisplayName'],
      ['raider_verified_results', 'reporterUid', 'reporterUid', 'reporterDisplayName'],
      ['raider_verified_results', 'targetUid', 'targetUid', 'targetDisplayName'],
      ['raider_verified_results', 'hunterUid', 'hunterUid', 'hunterDisplayName'],
      ['uag_message_reports', 'reporterUid', 'reporterUid', 'reporterName'],
      ['uag_message_reports', 'reportedUid', 'reportedUid', 'reportedName'],
      ['uag_conversation_reports', 'reporterUid', 'reporterUid', 'reporterName'],
      ['uag_conversation_reports', 'reportedUid', 'reportedUid', 'reportedName'],
      ['uag_conduct_reports', 'reporterUid', 'reporterUid', 'reporterName'],
      ['uag_conduct_reports', 'subjectUid', 'subjectUid', 'subjectName'],
      ['uag_community_contracts', 'ownerUid', 'ownerUid', 'ownerName'],
      ['uag_community_contracts', 'assigneeUid', 'assigneeUid', 'assigneeName'],
    ];

    for (const [collectionName, queryField, identityField, nameField] of trustRoleSpecs) {
      counts.anonymisedRecords += await mutateWhere(
        collectionName,
        queryField,
        uid,
        () =>
          deletedIdentityPatch({
            [identityField]: subjectKey,
            [nameField]: DELETED_RAIDER_LABEL,
            email: deletedValue(),
            targetGameIdentity: deletedValue(),
          }),
      );
    }

    // Legal acceptance/request evidence can be retained without a live account
    // identifier. Financial/billing ledgers remain untouched and are covered by
    // the disclosed regulatory/accounting retention category.
    for (const collectionName of [
      'legal_acceptance_events',
      'data_rights_requests',
      'uag_referral_terms_acceptances',
    ]) {
      counts.anonymisedRecords += await mutateWhere(
        collectionName,
        'uid',
        uid,
        () =>
          deletedIdentityPatch({
            uid: subjectKey,
            email: deletedValue(),
            displayName: deletedValue(),
          }),
      );
    }

    // Remove account-specific Storage objects. Safety evidence lives outside
    // these prefixes and is intentionally not deleted here.
    for (const prefix of [`users/${uid}/`, `legal_exports/${uid}/`]) {
      await bucket.deleteFiles({ prefix, force: true });
      counts.storagePrefixes += 1;
    }

    // Delete the canonical user document and every nested subcollection last,
    // after public/actionable surfaces have been removed.
    await deleteDocumentTree(db.collection('users').doc(uid));

    await tombstoneRef.set(
      {
        status: 'dataDeleted',
        dataDeletedAt: timestamp(),
        updatedAt: timestamp(),
        deletionCounts: counts,
      },
      { merge: true },
    );

    try {
      await auth.deleteUser(uid);
    } catch (error) {
      await tombstoneRef.set(
        {
          status: 'authDeletionFailed',
          updatedAt: timestamp(),
        },
        { merge: true },
      );
      throw error;
    }

    await tombstoneRef.set(
      {
        status: 'complete',
        completedAt: timestamp(),
        updatedAt: timestamp(),
      },
      { merge: true },
    );

    return {
      deleted: true,
      receiptId: accountDeletionKey(uid).slice(0, 16),
      retainedCategories: RETAINED_CATEGORIES,
    };
  }

  async function preventResurrection(event, uidParam = 'userId') {
    const after = event?.data?.after;
    if (!after || after.exists !== true) return;
    const uid = String(event?.params?.[uidParam] || '').trim();
    if (!uid) return;

    const tombstone = await db
      .collection('account_deletion_tombstones')
      .doc(accountDeletionKey(uid))
      .get();

    if (tombstone.exists) {
      await after.ref.delete();
    }
  }

  return {
    deleteAccount,
    preventResurrection,
  };
}

module.exports = {
  RECENT_AUTH_MAX_AGE_SECONDS,
  RETAINED_CATEGORIES,
  DIRECT_PRIVATE_DOCS,
  PRIVATE_QUERY_DELETIONS,
  accountDeletionKey,
  retainedSubjectKey,
  isRecentAuth,
  createAccountDeletionLifecycle,
};
