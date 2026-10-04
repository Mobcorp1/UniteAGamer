'use strict';

const crypto = require('node:crypto');

const FREE_REFERRALS_PER_REWARD = 10;
const PAID_REFERRALS_PER_REWARD = 5;
const VALID_ACTIONS = Object.freeze(['trades', 'raidCompanionPresets']);

class ReferralRewardError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.status = status;
  }
}

const count = value => Number.isInteger(Number(value)) && Number(value) >= 0
  ? Math.floor(Number(value))
  : 0;

function usageMonthKey(now = Date.now()) {
  const date = new Date(now);
  return `${date.getUTCFullYear()}-M${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

function earnedTokens(freeQualifiedCount, paidQualifiedCount) {
  return Math.floor(count(freeQualifiedCount) / FREE_REFERRALS_PER_REWARD) +
    Math.floor(count(paidQualifiedCount) / PAID_REFERRALS_PER_REWARD);
}

function referralStateRef(db, uid, now = Date.now()) {
  return db.collection('uag_referral_action_rewards')
    .doc(uid)
    .collection('months')
    .doc(usageMonthKey(now));
}

async function incrementQualifiedReferral({
  db,
  admin,
  uid,
  kind,
  sourceKey,
  now = Date.now(),
}) {
  if (!uid || !['free', 'paid'].includes(kind)) return null;
  const ref = referralStateRef(db, uid, now);
  const receiptId = sourceKey
    ? crypto.createHash('sha256').update(`${uid}:${kind}:${sourceKey}`).digest('hex')
    : '';
  const receiptRef = receiptId
    ? db.collection('uag_referral_action_qualification_receipts').doc(receiptId)
    : null;
  return db.runTransaction(async tx => {
    const [snapshot, receipt] = await Promise.all([
      tx.get(ref),
      receiptRef ? tx.get(receiptRef) : Promise.resolve(null),
    ]);
    if (receipt?.exists) {
      return { ...receipt.data(), duplicate: true };
    }
    const data = snapshot.data() || {};
    const freeCount = count(data.freeQualifiedCount) + (kind === 'free' ? 1 : 0);
    const paidCount = count(data.paidQualifiedCount) + (kind === 'paid' ? 1 : 0);
    const totalEarned = earnedTokens(freeCount, paidCount);
    const redeemed = count(data.redeemedTokens);
    const result = {
      uid,
      kind,
      periodKey: usageMonthKey(now),
      freeQualifiedCount: freeCount,
      paidQualifiedCount: paidCount,
      earnedTokens: totalEarned,
      redeemedTokens: redeemed,
      availableTokens: Math.max(0, totalEarned - redeemed),
    };
    tx.set(ref, {
      ...result,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: snapshot.exists
        ? data.createdAt || admin.firestore.FieldValue.serverTimestamp()
        : admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    if (receiptRef) {
      tx.set(receiptRef, {
        ...result,
        sourceKey,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return {
      freeQualifiedCount: freeCount,
      paidQualifiedCount: paidCount,
      earnedTokens: totalEarned,
      redeemedTokens: redeemed,
      availableTokens: Math.max(0, totalEarned - redeemed),
    };
  });
}

function createReferralActionRewardHandler({ db, auth, admin, now = Date.now }) {
  return async (req, res) => {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST required.' });
    try {
      const bearer = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (!bearer) throw new ReferralRewardError('Sign in to use referral rewards.', 401);
      const token = await auth.verifyIdToken(bearer[1], true);
      const uid = token.uid;
      const action = String(req.body?.action || '');
      const requestId = String(req.body?.requestId || '').trim().toLowerCase();
      if (!VALID_ACTIONS.includes(action) || !/^[a-f0-9]{32}$/.test(requestId)) {
        throw new ReferralRewardError('Invalid referral reward redemption.');
      }

      const time = now();
      const stateRef = referralStateRef(db, uid, time);
      const bonusRef = db.collection('uag_reward_bonuses')
        .doc(uid)
        .collection('months')
        .doc(usageMonthKey(time));
      const receiptRef = db.collection('uag_referral_action_redemptions')
        .doc(`${uid}_${requestId}`);

      const result = await db.runTransaction(async tx => {
        const [stateSnap, bonusSnap, receiptSnap] = await Promise.all([
          tx.get(stateRef),
          tx.get(bonusRef),
          tx.get(receiptRef),
        ]);
        if (receiptSnap.exists) {
          if (receiptSnap.data()?.action !== action) {
            throw new ReferralRewardError('Redemption request already used.', 409);
          }
          return { redeemed: true, alreadyRedeemed: true };
        }

        const state = stateSnap.data() || {};
        const freeCount = count(state.freeQualifiedCount);
        const paidCount = count(state.paidQualifiedCount);
        const totalEarned = earnedTokens(freeCount, paidCount);
        const redeemed = count(state.redeemedTokens);
        if (redeemed >= totalEarned) {
          throw new ReferralRewardError('No referral bonus action is ready to redeem.', 409);
        }

        const nextRedeemed = redeemed + 1;
        const bonusData = bonusSnap.data() || {};
        tx.set(stateRef, {
          uid,
          periodKey: usageMonthKey(time),
          earnedTokens: totalEarned,
          redeemedTokens: nextRedeemed,
          availableTokens: Math.max(0, totalEarned - nextRedeemed),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(bonusRef, {
          uid,
          periodKey: usageMonthKey(time),
          [action]: count(bonusData[action]) + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(receiptRef, {
          uid,
          action,
          requestId,
          periodKey: usageMonthKey(time),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
          redeemed: true,
          alreadyRedeemed: false,
          availableTokens: Math.max(0, totalEarned - nextRedeemed),
        };
      });
      return res.status(200).json(result);
    } catch (error) {
      const status = error instanceof ReferralRewardError
        ? error.status
        : String(error.code || '').startsWith('auth/') ? 401 : 503;
      return res.status(status).json({
        error: error instanceof ReferralRewardError
          ? error.message
          : status === 401
            ? 'Sign in again to use referral rewards.'
            : 'Referral rewards are temporarily unavailable. Try again.',
      });
    }
  };
}

function newRequestId() {
  return crypto.randomBytes(16).toString('hex');
}

module.exports = {
  FREE_REFERRALS_PER_REWARD,
  PAID_REFERRALS_PER_REWARD,
  VALID_ACTIONS,
  ReferralRewardError,
  usageMonthKey,
  earnedTokens,
  referralStateRef,
  incrementQualifiedReferral,
  createReferralActionRewardHandler,
  newRequestId,
};
