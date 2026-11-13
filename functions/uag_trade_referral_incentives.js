'use strict';

/**
 * Admin-approval-only 30-day temporary entitlement for verified paid
 * acquisition via a trading link. Defaults are deliberately disabled; an
 * admin must set enabled=true and enabledAt in the canonical config document.
 * One award per originator, no recurring renewal, no cash payout.
 */
const ESSENTIAL = Object.freeze({ minPeople: 3, minNetPence: 1200, tier: 'essential' });
const PREMIUM = Object.freeze({ minPeople: 6, minNetPence: 3000, tier: 'premium' });
const HOLD_DAYS = 30;
const REWARD_DAYS = 30;

function evaluateVerifiedConversions(rows) {
  const byReferred = new Map();
  for (const row of rows) {
    if (row.referralSource !== 'uag_trade_invite' || row.type !== 'invoice_paid' || row.reversalType) continue;
    if (!row.uid || !row.referralOwnerUid || row.uid === row.referralOwnerUid) continue;
    const pence = Number(row.eligibleNetAmountPence || 0);
    if (!Number.isFinite(pence) || pence <= 0) continue;
    // First bona fide paid subscriber is counted once, NOT once per renewal.
    if (!byReferred.has(row.uid)) byReferred.set(row.uid, pence);
  }
  return { paidPeople: byReferred.size,
    netPence: [...byReferred.values()].reduce((a, b) => a + b, 0) };
}

function rewardTier(people, pence) {
  if (people >= PREMIUM.minPeople && pence >= PREMIUM.minNetPence) return 'premium';
  if (people >= ESSENTIAL.minPeople && pence >= ESSENTIAL.minNetPence) return 'essential';
  return null;
}

async function evaluateAndGrant({ db, admin }) {
  const configSnap = await db.collection('config').doc('uag_trade_referral_incentives').get();
  const config = configSnap.data() || {};
  // Enabling incentives without an explicit approval time is unsafe.
  if (config.enabled !== true || !config.enabledAt?.toMillis) return;
  const enabledAt = config.enabledAt.toMillis();
  if (enabledAt > Date.now()) return;
  const minPeopleEssential = Math.max(ESSENTIAL.minPeople, Number(config.essentialMinPaid || ESSENTIAL.minPeople));
  const minNetEssential = Math.max(ESSENTIAL.minNetPence, Number(config.essentialMinNetPence || ESSENTIAL.minNetPence));
  const minPeoplePremium = Math.max(PREMIUM.minPeople, Number(config.premiumMinPaid || PREMIUM.minPeople));
  const minNetPremium = Math.max(PREMIUM.minNetPence, Number(config.premiumMinNetPence || PREMIUM.minNetPence));
  const cutoff = Date.now() - HOLD_DAYS * 86400000;
  const events = await db.collection('monetisation_events').where('referralSource', '==', 'uag_trade_invite').limit(1001).get();
  // Never award based on an incomplete scan if cohort size outgrows the current
  // small-beta routine. An admin must upgrade the batch strategy first.
  if (events.size > 1000) throw new Error('Trade referral event pagination required before incentive evaluation');
  const cohorts = new Map();
  for (const doc of events.docs) {
    const data = doc.data() || {};
    const at = data.createdAt?.toMillis?.() || 0;
    if (at < enabledAt || at > cutoff) continue;
    const uid = String(data.referralOwnerUid || '');
    if (!uid) continue;
    if (!cohorts.has(uid)) cohorts.set(uid, []);
    cohorts.get(uid).push({ ...data, timestamp: at });
  }
  for (const [uid, rows] of cohorts) {
    const [userSnap, claimSnap] = await Promise.all([
      db.collection('users').doc(uid).get(),
      db.collection('uag_trade_referral_incentive_claims').doc(uid).get(),
    ]);
    if (!userSnap.exists || claimSnap.exists) continue;
    const user = userSnap.data() || {};
    const tier = String(user.monetisation?.tier || user.tier || 'free').toLowerCase();
    const status = String(user.monetisation?.subscriptionStatus || user.subscriptionStatus || '').toLowerCase();
    if (tier !== 'free' && ['active', 'trialing', 'paid'].includes(status)) continue;
    // Account retention and current paid subscription are server-owned checks.
    const validRows = [];
    for (const row of rows.sort((a, b) => a.timestamp - b.timestamp)) {
      const referred = await db.collection('users').doc(row.uid).get();
      const person = referred.data() || {};
      const pTier = String(person.monetisation?.tier || person.tier || 'free').toLowerCase();
      const pStatus = String(person.monetisation?.subscriptionStatus || person.subscriptionStatus || '').toLowerCase();
      if (referred.exists && ['essential', 'premium'].includes(pTier) &&
          ['active', 'paid'].includes(pStatus)) validRows.push(row);
    }
    const verified = evaluateVerifiedConversions(validRows);
    const reward = verified.paidPeople >= minPeoplePremium && verified.netPence >= minNetPremium
      ? 'premium' : verified.paidPeople >= minPeopleEssential && verified.netPence >= minNetEssential
        ? 'essential' : null;
    if (!reward) continue;
    const claimRef = db.collection('uag_trade_referral_incentive_claims').doc(uid);
    const userRef = db.collection('users').doc(uid);
    const now = Date.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(now + REWARD_DAYS * 86400000);
    await db.runTransaction(async tx => {
      const [currentClaim, currentUser] = await Promise.all([tx.get(claimRef), tx.get(userRef)]);
      if (currentClaim.exists || !currentUser.exists) return;
      const person = currentUser.data() || {};
      if (['active', 'paid', 'trialing'].includes(String(person.monetisation?.subscriptionStatus || person.subscriptionStatus || '').toLowerCase()) &&
        ['essential', 'premium'].includes(String(person.monetisation?.tier || person.tier || '').toLowerCase())) return;
      tx.create(claimRef, { uid, type: reward, status: 'fulfilled',
        paidPeople: verified.paidPeople, verifiedNetPence: verified.netPence,
        configApprovedAt: config.enabledAt, createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt });
      tx.update(userRef, { 'creatorRewardEntitlements.uag_trade_referral_one_month': {
        grantId: 'uag_trade_referral_one_month', tier: reward,
        startedAt: admin.firestore.Timestamp.fromMillis(now), expiresAt,
        sourceCode: 'TRADE_REFERRAL_ONE_MONTH', sourceClaimPath: claimRef.path,
        rewardType: 'trade_referral_one_month',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }});
    });
  }
}

module.exports = { ESSENTIAL, PREMIUM, HOLD_DAYS, REWARD_DAYS, evaluateVerifiedConversions, rewardTier, evaluateAndGrant };
