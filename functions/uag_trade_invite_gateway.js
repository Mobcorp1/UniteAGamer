'use strict';

const crypto = require('crypto');

const INVITE_LIFETIME_MS = 30 * 24 * 60 * 60 * 1000;
const INVITE_PATTERN = /^[A-Za-z0-9_-]{28,96}$/;
const MAX_ISSUES_PER_DAY = 25;
const SIGNUP_GRACE_MS = 15 * 60 * 1000;

function publicInviteUrl(token) {
  if (!INVITE_PATTERN.test(token)) throw new Error('Invalid trade token');
  return `https://uniteagamer.com/t/${token}`;
}

function tokenDigest(token) {
  return crypto.createHash('sha256').update(token, 'utf8').digest('hex');
}

function safeAlias(value) {
  return String(value || '').replace(/[\u0000-\u001f\u007f<>]/g, '').trim().slice(0, 48);
}

function inviteFromUri(value) {
  let uri;
  try { uri = new URL(value); } catch (_) { return null; }
  if (uri.protocol !== 'https:' || !['unite-a-gamer.web.app', 'uniteagamer.com', 'www.uniteagamer.com'].includes(uri.host)) {
    return null;
  }
  const match = /^\/t\/([A-Za-z0-9_-]{28,96})\/?$/.exec(uri.pathname);
  return match ? match[1] : null;
}

function isValidInvite(data, nowMillis) {
  return data && data.active === true && data.expiresAt?.toMillis && data.expiresAt.toMillis() > nowMillis;
}

function buildGateway({ admin, db, auth }) {
  const stamp = () => admin.firestore.FieldValue.serverTimestamp();
  const time = (millis) => admin.firestore.Timestamp.fromMillis(millis);
  const clientOrigin = new Set(['https://unite-a-gamer.web.app', 'https://uniteagamer.com', 'https://www.uniteagamer.com']);

  async function principal(req) {
    const token = /^Bearer (\S+)$/.exec(String(req.headers.authorization || ''))?.[1];
    if (!token) return null;
    try { return await auth.verifyIdToken(token, true); } catch (_) { return null; }
  }

  function cors(req, res) {
    const origin = String(req.headers.origin || '');
    if (clientOrigin.has(origin)) {
      res.set('Access-Control-Allow-Origin', origin);
      res.set('Vary', 'Origin');
      res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      res.set('Access-Control-Max-Age', '3600');
    }
    if (req.method === 'OPTIONS') { res.status(204).send(''); return true; }
    return false;
  }

  return async (req, res) => {
    if (cors(req, res)) return;
    if (req.method !== 'POST' || !req.is('application/json')) {
      res.status(405).json({ error: 'JSON POST required' }); return;
    }
    const action = String(req.body?.action || '');
    if (!['create', 'resolve', 'claim', 'revoke', 'legacyCapture'].includes(action)) {
      res.status(400).json({ error: 'Unknown request' }); return;
    }
    try {
      const now = Date.now();
      const account = action === 'resolve' ? null : await principal(req);
      if (action !== 'resolve' && !account) {
        res.status(401).json({ error: 'Sign in required' }); return;
      }
      if (action === 'legacyCapture') {
        const referrerUid = String(req.body?.referrerUid || '');
        const code = String(req.body?.code || '').trim().toUpperCase();
        if (!/^[A-Z0-9-]{6,64}$/.test(code) || !/^[a-zA-Z0-9]{8,128}$/.test(referrerUid)) {
          res.status(400).json({ error: 'Invalid legacy referral' }); return;
        }
        const codeSnap = await db.collection('uag_community_referral_codes').doc(code).get();
        if (!codeSnap.exists || codeSnap.data()?.ownerUid !== referrerUid || codeSnap.data()?.active === false ||
            codeSnap.data()?.attributionOnly === true || referrerUid === account.uid) {
          res.status(403).json({ error: 'Invalid legacy referral' }); return;
        }
        const referredAuth = await auth.getUser(account.uid);
        const accountCreated = Date.parse(referredAuth.metadata.creationTime || '');
        if (!Number.isFinite(accountCreated) || Date.now() - accountCreated > 14 * 86400000) {
          res.status(200).json({ status: 'existing_member' }); return;
        }
        const attributionRef = db.collection('users').doc(account.uid).collection('monetisation_usage').doc('community_referral_attribution');
        const ownerRef = db.collection('users').doc(referrerUid);
        let status = 'already_attributed';
        await db.runTransaction(async tx => {
          const [attribution, owner] = await Promise.all([tx.get(attributionRef), tx.get(ownerRef)]);
          if (attribution.exists || !owner.exists) return;
          tx.create(attributionRef, { referredUid: account.uid, referrerUid, code, status: 'pending_validation',
            source: 'community_referral_link', capturedAt: stamp(), updatedAt: stamp() });
          tx.update(ownerRef, { 'communityReferral.pendingReferrals': admin.firestore.FieldValue.increment(1),
            'communityReferral.updatedAt': stamp() });
          status = 'captured';
        });
        res.status(200).json({ status }); return;
      }
      if (action === 'create') {
        const uid = account.uid;
        const [user, trader] = await Promise.all([
          db.collection('users').doc(uid).get(),
          db.collection('arc_trader_profiles').doc(uid).get(),
        ]);
        if (!user.exists || user.data()?.disabled === true) {
          res.status(403).json({ error: 'Raider profile unavailable' }); return;
        }
        const profile = trader.data() || {};
        const userData = user.data() || {};
        const name = safeAlias(profile.uagName || profile.uagId || userData.traderProfile?.uagName || userData.displayName || 'UAG Raider');
        const token = crypto.randomBytes(32).toString('base64url');
        const digest = tokenDigest(token);
        const desiredProgramme = String(req.body?.programmeCode || '').trim().toUpperCase();
        let programme = false;
        if (desiredProgramme && /^[A-Z0-9-]{6,64}$/.test(desiredProgramme)) {
          const [registry, terms] = await Promise.all([
            db.collection('uag_community_referral_codes').doc(desiredProgramme).get(),
            db.collection('uag_referral_terms_acceptances').doc(uid).get(),
          ]);
          programme = registry.data()?.ownerUid === uid && registry.data()?.active !== false &&
            registry.data()?.attributionOnly !== true && terms.data()?.accepted === true;
        }
        const code = programme ? desiredProgramme : `TRADE${crypto.randomBytes(10).toString('hex').toUpperCase()}`;
        const dateKey = new Date(now).toISOString().slice(0, 10);
        const limitRef = db.collection('uag_trade_invite_issue_limits').doc(uid);
        const inviteRef = db.collection('uag_trade_invites').doc(digest);
        const codeRef = db.collection('uag_community_referral_codes').doc(code);
        let limited = false;
        await db.runTransaction(async tx => {
          const existing = await tx.get(limitRef);
          const state = existing.data() || {};
          const count = state.day === dateKey ? Number(state.count || 0) : 0;
          if (count >= MAX_ISSUES_PER_DAY) { limited = true; return; }
          tx.set(limitRef, { uid, day: dateKey, count: count + 1, updatedAt: stamp() });
          tx.create(inviteRef, { ownerUid: uid, alias: name, code, active: true,
            enrolledProgramme: programme, createdAt: stamp(),
            expiresAt: time(now + INVITE_LIFETIME_MS), version: 1 });
          if (!programme) tx.create(codeRef, { code, ownerUid: uid, active: true, attributionOnly: true,
            source: 'uag_trade_invite', createdAt: stamp(), expiresAt: time(now + INVITE_LIFETIME_MS) });
        });
        if (limited) { res.status(429).json({ error: 'Daily sharing limit reached' }); return; }
        res.status(200).json({ url: publicInviteUrl(token), alias: name,
          expiresAt: new Date(now + INVITE_LIFETIME_MS).toISOString() });
        return;
      }
      const raw = String(req.body?.token || '');
      if (!INVITE_PATTERN.test(raw)) { res.status(404).json({ error: 'Trading link invalid' }); return; }
      const inviteRef = db.collection('uag_trade_invites').doc(tokenDigest(raw));
      const invite = await inviteRef.get();
      if (!invite.exists || !isValidInvite(invite.data(), now)) {
        res.status(404).json({ error: 'Trading link expired or revoked' }); return;
      }
      const data = invite.data();
      if (action === 'resolve') {
        res.status(200).json({ alias: safeAlias(data.alias), status: 'valid' }); return;
      }
      if (action === 'revoke') {
        if (data.ownerUid !== account.uid) { res.status(403).json({ error: 'Not your link' }); return; }
        // Keep the code registry for recipients already attributed before
        // revocation, while the opaque URL stops accepting new claims.
        await inviteRef.update({ active: false, revokedAt: stamp() });
        res.status(200).json({ status: 'revoked' }); return;
      }
      if (action === 'claim') {
        const uid = account.uid;
        if (uid === data.ownerUid) { res.status(403).json({ error: 'Self-referrals are not eligible' }); return; }
        const profileRef = db.collection('users').doc(uid);
        const attributionRef = profileRef.collection('monetisation_usage').doc('community_referral_attribution');
        const referredAuth = await auth.getUser(uid);
        const accountCreated = Date.parse(referredAuth.metadata.creationTime || '');
        const inviteCreated = data.createdAt?.toMillis?.() || 0;
        const newlyRegistered = Number.isFinite(accountCreated) &&
          accountCreated + SIGNUP_GRACE_MS >= inviteCreated && accountCreated <= now;
        let attribution = 'existing_member';
        if (newlyRegistered) {
          const ownerRef = db.collection('users').doc(data.ownerUid);
          await db.runTransaction(async tx => {
            const [current, owner, inviteCheck, code] = await Promise.all([
              tx.get(attributionRef), tx.get(ownerRef), tx.get(inviteRef),
              tx.get(db.collection('uag_community_referral_codes').doc(data.code)),
            ]);
            if (current.exists) { attribution = 'already_attributed'; return; }
            if (!owner.exists || !isValidInvite(inviteCheck.data(), Date.now()) || code.data()?.active !== true) {
              attribution = 'invalid'; return;
            }
            tx.create(attributionRef, { referredUid: uid, referrerUid: data.ownerUid, code: data.code,
              status: 'pending_validation', source: data.enrolledProgramme === true
                ? 'uag_community_referral' : 'uag_trade_invite',
              capturedAt: stamp(), updatedAt: stamp() });
            tx.update(ownerRef, { 'communityReferral.pendingReferrals': admin.firestore.FieldValue.increment(1),
              'communityReferral.updatedAt': stamp() });
            attribution = 'captured';
          });
        }
        if (attribution === 'invalid') { res.status(410).json({ error: 'Trading link unavailable' }); return; }
        res.status(200).json({ status: attribution, alias: safeAlias(data.alias), ownerUid: data.ownerUid });
        return;
      }
    } catch (err) {
      console.error('UAG trade invitation gateway error:', err?.code || err?.message || 'unknown');
      res.status(500).json({ error: 'Trading link service temporarily unavailable' });
    }
  };
}

module.exports = { tokenDigest, publicInviteUrl, safeAlias, inviteFromUri, isValidInvite, buildGateway };
