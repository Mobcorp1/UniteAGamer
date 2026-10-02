'use strict';

const crypto = require('node:crypto');
const { COMMERCIAL_ECONOMY } = require('./uag_commercial_economy');
const POLICY = COMMERCIAL_ECONOMY.raiderMarks;
const LIVE_UNIT = 'ca-app-pub-2994575443987525/3866328391';
const TEST_UNIT = 'ca-app-pub-3940256099942544/5224354917';
const PLACEMENT = 'arc_free_intel_refresh';
const SESSION_MS = 60 * 60 * 1000;
const KEY_URL = 'https://www.gstatic.com/admob/reward/verifier-keys.json';
let cachedKeys;
let keysLoadedAt = 0;

class RewardError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}
const millis = value => typeof value?.toMillis === 'function' ? value.toMillis() :
  typeof value === 'number' ? value : Date.parse(value || '') || 0;
const count = value => Number.isInteger(value) && value >= 0 ? value : 0;
const dayKey = now => new Date(now).toISOString().slice(0, 10);
const monthKey = now => new Date(now).toISOString().slice(0, 7);
const usageMonthKey = now => monthKey(now).replace('-', '-M');
const tierName = value => {
  const tier = String(value || '').trim().toLowerCase();
  if (['premium', 'elite', 'elite_raider', 'elite-raider'].includes(tier)) return 'premium';
  if (['essential', 'active_raider', 'active-raider'].includes(tier)) return 'essential';
  return 'free';
};
function effectiveTier(user, now) {
  const internal = user.isAdmin === true || user.isDev === true;
  const mode = String(user.entitlementTest?.mode || 'real').toLowerCase();
  if (internal && mode !== 'real') {
    return mode === 'free' ? 'free' : mode === 'essential' ? 'essential' : 'premium';
  }
  if (internal) return 'premium';
  const m = user.monetisation || {};
  const pass = m.premiumPass || user.premiumPass || {};
  if (['day24', 'week7'].includes(pass.type) && millis(pass.expiresAt) > now) return 'premium';
  const status = String(user.subscriptionStatus ?? m.subscriptionStatus ?? '').trim().toLowerCase();
  let tier = ['active', 'trialing'].includes(status) ?
    tierName(user.subscriptionTier ?? user.tier ?? user.planTier ?? m.tier) : 'free';
  for (const grant of Object.values(user.creatorRewardEntitlements || {})) {
    if (millis(grant.startedAt) <= now && millis(grant.expiresAt) > now) {
      const candidate = tierName(grant.tier);
      if (candidate === 'premium') return 'premium';
      if (candidate === 'essential') tier = 'essential';
    }
  }
  return tier;
}
function normalizedWallet(wallet = {}, now = Date.now()) {
  return {
    balance: count(wallet.balance),
    day: dayKey(now), month: monthKey(now),
    adsToday: wallet.day === dayKey(now) ? count(wallet.adsToday) : 0,
    adsThisMonth: wallet.month === monthKey(now) ? count(wallet.adsThisMonth) : 0,
    redemptionsThisMonth: wallet.month === monthKey(now) ? count(wallet.redemptionsThisMonth) : 0,
    lastVerifiedAt: millis(wallet.lastVerifiedAt),
  };
}
function assertCanEarn(wallet, now) {
  if (wallet.balance >= POLICY.walletCap) throw new RewardError('Your Raider Mark wallet is full.', 409);
  if (wallet.adsToday >= POLICY.maxRewardedAdsPerDay) throw new RewardError('Daily reward limit reached.', 429);
  if (wallet.adsThisMonth >= POLICY.maxRewardedAdsPerMonth) throw new RewardError('Monthly reward limit reached.', 429);
  if (wallet.lastVerifiedAt && now - wallet.lastVerifiedAt < POLICY.minimumIntervalMinutes * 60000) {
    throw new RewardError('Wait 20 minutes between rewarded ads.', 429);
  }
}
async function googleKeys() {
  if (cachedKeys && Date.now() - keysLoadedAt < 12 * 60 * 60 * 1000) return cachedKeys;
  const response = await fetch(KEY_URL, { signal: AbortSignal.timeout(10000) });
  if (!response.ok) throw new RewardError('Reward verification temporarily unavailable.', 503);
  const data = await response.json();
  const keys = new Map((data.keys || []).map(key => [String(key.keyId), key.pem]));
  if (!keys.size) throw new RewardError('Reward verification keys unavailable.', 503);
  cachedKeys = keys; keysLoadedAt = Date.now();
  return keys;
}
async function verifyCallback(rawUrl, keyProvider = googleKeys) {
  const raw = rawUrl.slice(rawUrl.indexOf('?') + 1);
  const match = /^(.*)&signature=([^&]+)&key_id=(\d+)$/.exec(raw);
  if (!rawUrl.includes('?') || !match) throw new RewardError('Malformed verification callback.');
  const params = new URLSearchParams(raw);
  for (const key of new Set(params.keys())) {
    if (params.getAll(key).length !== 1) throw new RewardError('Duplicate verification parameter.');
  }
  let keys = await keyProvider();
  if (!keys.has(match[3]) && keyProvider === googleKeys) {
    cachedKeys = null; keys = await googleKeys();
  }
  const pem = keys.get(match[3]);
  if (!pem || !crypto.verify('sha256', Buffer.from(match[1], 'utf8'), pem,
    Buffer.from(decodeURIComponent(match[2]), 'base64url'))) {
    throw new RewardError('Invalid reward signature.', 403);
  }
  const event = Object.fromEntries(params);
  if (!/^[a-f0-9]{32}$/.test(event.custom_data || '') || !event.user_id ||
    !/^[a-zA-Z0-9_-]{1,128}$/.test(event.transaction_id || '') ||
    Number(event.reward_amount) !== POLICY.marksPerCompletedAd ||
    ![LIVE_UNIT, TEST_UNIT].includes(event.ad_unit) ||
    !Number.isSafeInteger(Number(event.timestamp))) {
    throw new RewardError('Invalid reward data.');
  }
  return event;
}
function createRewardHandlers({ db, auth, now = Date.now, keyProvider = googleKeys }) {
  const sessionRef = id => db.collection('uag_reward_sessions').doc(id);
  const walletRef = (uid, test) => db.collection(test ? 'uag_reward_test_wallets' : 'uag_reward_wallets').doc(uid);
  const bonusRef = (uid, time) => db.collection('uag_reward_bonuses').doc(uid).collection('months').doc(usageMonthKey(time));
  const api = fn => async (req, res) => {
    if (req.method !== 'POST') return res.status(405).json({ error: 'POST required.' });
    try {
      const bearer = /^Bearer (.+)$/.exec(req.headers.authorization || '');
      if (!bearer) throw new RewardError('Sign in to use rewards.', 401);
      const token = await auth.verifyIdToken(bearer[1], true);
      const result = await fn(token.uid, req.body || {});
      return res.status(200).json(result);
    } catch (error) {
      const status = error instanceof RewardError ? error.status :
        String(error.code || '').startsWith('auth/') ? 401 : 503;
      return res.status(status).json({ error: error instanceof RewardError ? error.message :
        status === 401 ? 'Sign in again to use rewards.' : 'Rewards are temporarily unavailable. Try again.' });
    }
  };
  const prepare = api(async (uid, body) => {
    if (body.placement !== PLACEMENT || !['test', 'live'].includes(body.inventory)) {
      throw new RewardError('Unknown reward placement or inventory.');
    }
    const test = body.inventory === 'test';
    const time = now();
    const id = crypto.randomBytes(16).toString('hex');
    await db.runTransaction(async tx => {
      const [userSnap, settingsSnap, walletSnap] = await Promise.all([
        tx.get(db.collection('users').doc(uid)), tx.get(db.collection('app_config').doc('ads')),
        tx.get(walletRef(uid, test)),
      ]);
      const settings = settingsSnap.data() || {};
      if (!userSnap.exists || effectiveTier(userSnap.data(), time) !== 'free') throw new RewardError('Rewards are available to Free Raiders only.', 403);
      if (settings.adsEnabled === false || settings.rewardedEnabled === false) throw new RewardError('Rewarded ads are currently disabled.', 403);
      if (!test && (settings.productionAdsEnabled !== true || settings.forceTestAds !== false || settings.rewardedSsvReady !== true)) {
        throw new RewardError('Live rewarded ads are not enabled yet.', 409);
      }
      const wallet = normalizedWallet(walletSnap.data(), time);
      assertCanEarn(wallet, time);
      if (millis(walletSnap.data()?.pendingExpiresAt) > time) throw new RewardError('A rewarded ad is already in progress.', 409);
      tx.set(sessionRef(id), { uid, inventory: body.inventory, placement: PLACEMENT,
        status: 'pending', createdAt: time, expiresAt: time + SESSION_MS });
      tx.set(walletRef(uid, test), { ...wallet, pendingSession: id, pendingExpiresAt: time + SESSION_MS }, { merge: true });
    });
    return { sessionId: id, inventory: body.inventory, adUnitId: test ? TEST_UNIT : LIVE_UNIT };
  });
  const cancel = api(async (uid, body) => {
    if (!/^[a-f0-9]{32}$/.test(body.sessionId || '')) throw new RewardError('Invalid session.');
    await db.runTransaction(async tx => {
      const ref = sessionRef(body.sessionId), snap = await tx.get(ref), data = snap.data();
      if (!data || data.uid !== uid) throw new RewardError('Session not found.', 404);
      if (data.status !== 'pending') return;
      const wr = walletRef(uid, data.inventory === 'test'), ws = await tx.get(wr);
      tx.set(ref, { status: 'cancelled' }, { merge: true });
      if (ws.data()?.pendingSession === body.sessionId) tx.set(wr, { pendingSession: null, pendingExpiresAt: 0 }, { merge: true });
    });
    return { cancelled: true };
  });
  const redeem = api(async (uid, body) => {
    if (!['trades', 'matchmakingSearches'].includes(body.action) || !/^[a-f0-9]{32}$/.test(body.requestId || '')) throw new RewardError('Invalid redemption.');
    const time = now(), wr = walletRef(uid, false), br = bonusRef(uid, time);
    const receipt = db.collection('uag_reward_redemptions').doc(`${uid}_${body.requestId}`);
    return db.runTransaction(async tx => {
      const [user, walletSnap, bonus, previous] = await Promise.all([
        tx.get(db.collection('users').doc(uid)), tx.get(wr), tx.get(br), tx.get(receipt),
      ]);
      if (previous.exists) {
        if (previous.data().action !== body.action) throw new RewardError('Redemption request already used.', 409);
        return { redeemed: true, alreadyRedeemed: true };
      }
      if (!user.exists || effectiveTier(user.data(), time) !== 'free') throw new RewardError('Rewards are available to Free Raiders only.', 403);
      const wallet = normalizedWallet(walletSnap.data(), time);
      if (wallet.balance < POLICY.marksPerBonusAction) throw new RewardError('You need 5 Raider Marks to redeem.', 409);
      if (wallet.redemptionsThisMonth >= POLICY.maxBonusRedemptionsPerMonth) throw new RewardError('Monthly redemption limit reached.', 429);
      tx.set(wr, { ...wallet, balance: wallet.balance - POLICY.marksPerBonusAction,
        redemptionsThisMonth: wallet.redemptionsThisMonth + 1 }, { merge: true });
      tx.set(br, { uid, periodKey: usageMonthKey(time), [body.action]: count(bonus.data()?.[body.action]) + 1 }, { merge: true });
      tx.set(receipt, { uid, action: body.action, createdAt: time, periodKey: usageMonthKey(time) });
      return { redeemed: true, alreadyRedeemed: false };
    });
  });
  const ssv = async (req, res) => {
    if (req.method !== 'GET') return res.status(405).send('GET required');
    try {
      const event = await verifyCallback(req.originalUrl || req.url, keyProvider);
      const eventTime = Number(event.timestamp), time = now();
      const receipt = db.collection('uag_reward_transactions').doc(event.transaction_id);
      await db.runTransaction(async tx => {
        const [previous, session] = await Promise.all([tx.get(receipt), tx.get(sessionRef(event.custom_data))]);
        if (previous.exists) {
          if (previous.data().sessionId !== event.custom_data) throw new RewardError('Transaction already used.', 409);
          return;
        }
        const data = session.data();
        if (!data || data.uid !== event.user_id || data.status !== 'pending' ||
          data.placement !== PLACEMENT || event.ad_unit !== (data.inventory === 'test' ? TEST_UNIT : LIVE_UNIT) ||
          eventTime < data.createdAt - 60000 || eventTime > data.expiresAt || eventTime > time + 60000 ||
          time - eventTime > 24 * 60 * 60 * 1000) throw new RewardError('Reward session does not match.', 403);
        const wr = walletRef(data.uid, data.inventory === 'test');
        const [ws, user] = await Promise.all([tx.get(wr), tx.get(db.collection('users').doc(data.uid))]);
        if (!user.exists) throw new RewardError('Reward account no longer exists.', 410);
        // Honour a completed ad even if the user upgraded while it was playing.
        const wallet = normalizedWallet(ws.data(), time);
        assertCanEarn(wallet, time);
        tx.set(wr, { ...wallet, balance: wallet.balance + POLICY.marksPerCompletedAd,
          adsToday: wallet.adsToday + 1, adsThisMonth: wallet.adsThisMonth + 1,
          lastVerifiedAt: time,
          ...(ws.data()?.pendingSession === event.custom_data ? { pendingSession: null, pendingExpiresAt: 0 } : {}),
        }, { merge: true });
        tx.set(sessionRef(event.custom_data), { status: 'verified', verifiedAt: time, transactionId: event.transaction_id }, { merge: true });
        tx.set(receipt, { sessionId: event.custom_data, inventory: data.inventory, verifiedAt: time });
      });
      return res.status(200).send('OK');
    } catch (error) {
      return res.status(error instanceof RewardError ? error.status : 503).send('Verification failed');
    }
  };
  return { prepare, cancel, redeem, ssv };
}
module.exports = { createRewardHandlers, verifyCallback, effectiveTier, normalizedWallet,
  assertCanEarn, RewardError, LIVE_UNIT, TEST_UNIT, PLACEMENT, POLICY };
