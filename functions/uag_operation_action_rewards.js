'use strict';

const { usageMonthKey } = require('./uag_referral_action_rewards');

const VALID_COMPLETION_ACTIONS = Object.freeze([
  'trades',
  'matchmakingSearches',
  'premiumIntelUnlocks',
  'raidCompanionPresets',
]);

const MONTHLY_OPERATION_REWARDS = Object.freeze({
  monthly_trader_bronze: Object.freeze({
    action: 'trades',
    target: 5,
    label: '+1 Trade Action',
  }),
  monthly_match_raider: Object.freeze({
    action: 'matchmakingSearches',
    target: 3,
    label: '+1 Match Raider Search',
  }),
  monthly_intel_network: Object.freeze({
    action: 'premiumIntelUnlocks',
    target: 5,
    label: '+1 Raid Intelligence Unlock',
  }),
  monthly_raid_runner: Object.freeze({
    action: 'raidCompanionPresets',
    target: 3,
    label: '+1 Raid Planner Run',
  }),
});

class OperationRewardError extends Error {
  constructor(message, status = 400) {
    super(message);
    this.status = status;
  }
}

const count = value => Number.isInteger(Number(value)) && Number(value) >= 0
  ? Math.floor(Number(value))
  : 0;

function createOperationActionRewardHandler({ db, auth, admin, now = Date.now }) {
  return async (req, res) => {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST required.' });
    try {
      const bearer = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (!bearer) throw new OperationRewardError('Sign in to claim Operation rewards.', 401);
      const token = await auth.verifyIdToken(bearer[1], true);
      const uid = token.uid;
      const operationId = String(req.body?.operationId || '').trim();
      const policy = MONTHLY_OPERATION_REWARDS[operationId];
      if (!policy) throw new OperationRewardError('This Operation does not award a core action.', 400);

      const time = now();
      const periodKey = usageMonthKey(time);
      const progressRef = db.collection('arc_operation_progress')
        .doc(uid)
        .collection('operations')
        .doc(operationId);
      const bonusRef = db.collection('uag_reward_bonuses')
        .doc(uid)
        .collection('months')
        .doc(periodKey);
      const receiptRef = db.collection('uag_operation_action_redemptions')
        .doc(`${uid}_${periodKey}_${operationId}`);

      const result = await db.runTransaction(async tx => {
        const [progressSnap, bonusSnap, receiptSnap] = await Promise.all([
          tx.get(progressRef),
          tx.get(bonusRef),
          tx.get(receiptRef),
        ]);
        if (receiptSnap.exists) {
          return {
            redeemed: true,
            alreadyRedeemed: true,
            action: policy.action,
            label: policy.label,
          };
        }

        const progress = progressSnap.data() || {};
        if (String(progress.periodKey || '') !== periodKey) {
          throw new OperationRewardError('Complete this Operation during the current monthly rotation first.', 409);
        }
        if (count(progress.progress) < policy.target) {
          throw new OperationRewardError('This Operation is not complete yet.', 409);
        }

        const bonusData = bonusSnap.data() || {};
        tx.set(bonusRef, {
          uid,
          periodKey,
          [policy.action]: count(bonusData[policy.action]) + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(receiptRef, {
          uid,
          periodKey,
          operationId,
          action: policy.action,
          label: policy.label,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.set(progressRef, {
          commercialRewardClaimed: true,
          commercialRewardClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
          redeemed: true,
          alreadyRedeemed: false,
          action: policy.action,
          label: policy.label,
        };
      });
      return res.status(200).json(result);
    } catch (error) {
      const status = error instanceof OperationRewardError
        ? error.status
        : String(error.code || '').startsWith('auth/') ? 401 : 503;
      return res.status(status).json({
        error: error instanceof OperationRewardError
          ? error.message
          : status === 401
            ? 'Sign in again to claim Operation rewards.'
            : 'Operation rewards are temporarily unavailable. Try again.',
      });
    }
  };
}


function createOperationCompletionRewardHandler({ db, auth, admin, now = Date.now }) {
  return async (req, res) => {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST required.' });
    try {
      const bearer = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (!bearer) throw new OperationRewardError('Sign in to claim Operation rewards.', 401);
      const token = await auth.verifyIdToken(bearer[1], true);
      const uid = token.uid;
      const action = String(req.body?.action || '').trim();
      if (!VALID_COMPLETION_ACTIONS.includes(action)) {
        throw new OperationRewardError('Choose a valid core action reward.', 400);
      }

      const time = now();
      const periodKey = usageMonthKey(time);
      const progressRefs = Object.keys(MONTHLY_OPERATION_REWARDS).map(operationId => ({
        operationId,
        policy: MONTHLY_OPERATION_REWARDS[operationId],
        ref: db.collection('arc_operation_progress')
          .doc(uid)
          .collection('operations')
          .doc(operationId),
      }));
      const bonusRef = db.collection('uag_reward_bonuses')
        .doc(uid)
        .collection('months')
        .doc(periodKey);
      const receiptRef = db.collection('uag_operation_completion_redemptions')
        .doc(`${uid}_${periodKey}`);

      const result = await db.runTransaction(async tx => {
        const progressSnaps = await Promise.all(progressRefs.map(item => tx.get(item.ref)));
        const [bonusSnap, receiptSnap] = await Promise.all([
          tx.get(bonusRef),
          tx.get(receiptRef),
        ]);
        if (receiptSnap.exists) {
          return {
            redeemed: true,
            alreadyRedeemed: true,
            action: receiptSnap.data()?.action || action,
          };
        }

        for (let index = 0; index < progressRefs.length; index += 1) {
          const item = progressRefs[index];
          const data = progressSnaps[index].data() || {};
          if (String(data.periodKey || '') !== periodKey || count(data.progress) < item.policy.target) {
            throw new OperationRewardError('Complete all four monthly core Operations first.', 409);
          }
        }

        const bonusData = bonusSnap.data() || {};
        tx.set(bonusRef, {
          uid,
          periodKey,
          [action]: count(bonusData[action]) + 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(receiptRef, {
          uid,
          periodKey,
          action,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        for (const item of progressRefs) {
          tx.set(item.ref, {
            completionRewardClaimed: true,
            completionRewardAction: action,
            completionRewardClaimedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        }
        return { redeemed: true, alreadyRedeemed: false, action };
      });
      return res.status(200).json(result);
    } catch (error) {
      const status = error instanceof OperationRewardError
        ? error.status
        : String(error.code || '').startsWith('auth/') ? 401 : 503;
      return res.status(status).json({
        error: error instanceof OperationRewardError
          ? error.message
          : status === 401
            ? 'Sign in again to claim Operation rewards.'
            : 'Operation rewards are temporarily unavailable. Try again.',
      });
    }
  };
}

module.exports = {
  VALID_COMPLETION_ACTIONS,
  MONTHLY_OPERATION_REWARDS,
  OperationRewardError,
  createOperationActionRewardHandler,
  createOperationCompletionRewardHandler,
};
