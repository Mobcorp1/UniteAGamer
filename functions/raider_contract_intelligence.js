'use strict';

const { createHash } = require('node:crypto');
const { hasVideoTrack } = require('./raider_contract_verification');
const DAY = 86400000;
const terminal = new Set(['completed', 'rejected', 'cancelled', 'expired', 'overturned']);
const date = value => value?.toDate ? value.toDate() : value instanceof Date ? value : null;
const expired = (c, now) => date(c.expiresAt) != null && date(c.expiresAt) <= now;
const effectiveStatus = (c, now) => !terminal.has(c.status) && expired(c, now) ? 'expired' : c.status;
const key = (...parts) => createHash('sha256').update(JSON.stringify(parts)).digest('hex');

// Only moderator-verified incident context is a signal. This is not presence,
// login history, or a prediction of where a person currently is.
function deriveIntelligence(reports, now, windowDays = 30) {
  const days = Math.max(7, Math.min(90, Number(windowDays) || 30));
  const start = new Date(now.getTime() - days * DAY);
  const seen = new Set();
  const eligible = reports.filter(r => {
    if (r.status !== 'approved' || r.incidentVerification !== 'verified' || !date(r.incidentAt) ||
        date(r.incidentAt) < start || date(r.incidentAt) > now) return false;
    const identity = r.verifiedEvidence?.contentHash;
    if (identity && seen.has(identity)) return false;
    if (identity) seen.add(identity);
    return true;
  });
  const maps = {}, regions = {}, hours = {}, weekdays = {};
  const knownMaps = new Set(['dam_battlegrounds', 'buried_city', 'spaceport', 'blue_gate', 'stella_montis']);
  const knownRegions = new Set(['Europe', 'North America', 'South America', 'Asia', 'Oceania', 'Middle East', 'Africa']);
  for (const r of eligible) {
    if (knownMaps.has(r.mapId)) maps[r.mapId] = (maps[r.mapId] || 0) + 1;
    if (knownRegions.has(r.serverRegion)) regions[r.serverRegion] = (regions[r.serverRegion] || 0) + 1;
    const at = date(r.incidentAt);
    const bucket = Math.floor(at.getUTCHours() / 6);
    hours[bucket] = (hours[bucket] || 0) + 1;
    weekdays[at.getUTCDay()] = (weekdays[at.getUTCDay()] || 0) + 1;
  }
  const independent = new Set(eligible.map(r => r.reporterUid)).size >= 2;
  const recent = eligible.some(r => now - date(r.incidentAt) <= 7 * DAY);
  const sufficient = eligible.length >= 3 && independent && recent;
  const dominant = counts => {
    const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);
    return sufficient && sorted[0]?.[1] >= 3 && sorted[0][1] / eligible.length >= 0.6 ? sorted[0][0] : 'UNKNOWN';
  };
  return { mapAffinity: dominant(maps), regionAffinity: dominant(regions),
    activityHourBuckets: hours, activityDayBuckets: weekdays,
    confidence: sufficient ? 'MEDIUM' : 'LOW', recentActivityConfidence: 'UNKNOWN',
    verifiedIncidentCount: eligible.length, dataWindowStart: start, dataWindowEnd: now,
    lastDerivedAt: now, expiresAt: new Date(now.getTime() + DAY) };
}
function hunterProjection(id, c, intel, serverPreference) {
  return { id, targetDisplayName: c.targetDisplayName || 'Raider', category: c.category || 'other',
    status: 'available', evidenceState: 'VERIFIED', rewardSummary: c.rewardSummary || 'No reward offered',
    mapAffinity: intel.mapAffinity, confidence: intel.confidence,
    activityLikelihood: 'UNKNOWN', regionMatch: intel.regionAffinity !== 'UNKNOWN' &&
      intel.regionAffinity === serverPreference ? 'STRONG' : 'UNKNOWN' };
}
function targetProjection(id, c, now) {
  const status = effectiveStatus(c, now);
  return { id, category: c.category || 'other', status,
    evidenceState: ['verified', 'overturned', 'rejected'].includes(c.incidentVerification) ? c.incidentVerification.toUpperCase() : 'AWAITING REVIEW',
    challengeStatus: c.challengeStatus || 'none',
    canChallenge: !['overturned', 'rejected', 'cancelled'].includes(status) && !c.challengeStatus };
}
function canDiscover(c, uid, now) {
  return !!c.targetUid && c.targetUid !== uid && c.reporterUid !== uid &&
    c.incidentVerification === 'verified' && c.status === 'available' && !expired(c, now);
}

function createRaiderContractIntelligence({ db, bucket, timestamp, HttpsError, getAuthUser,
  now = () => new Date(), windowDays = 30 }) {
  const fail = (code, message) => { throw new HttpsError(code, message); };
  const ref = (collection, id) => db.collection(collection).doc(id);
  const read = async (collection, id) => (await ref(collection, id).get()).data();
  const id = value => {
    if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) fail('invalid-argument', 'Invalid reference.');
    return value;
  };
  function actor(request) {
    if (!request.auth?.uid) fail('unauthenticated', 'Sign in required.');
    return request.auth.uid;
  }
  async function eligible(uid, mode) {
    const [user, restrictions, auth] = await Promise.all([
      read('users', uid), read('arc_contract_restrictions', uid), getAuthUser(uid),
    ]);
    if (auth.disabled || user?.ageVerification?.verifiedOver18 !== true || restrictions?.[mode] === true) {
      fail('permission-denied', 'This account is not eligible for this Contract action.');
    }
    return user;
  }
  async function moderator(uid) {
    const [u, auth] = await Promise.all([read('users', uid), getAuthUser(uid)]);
    if (auth.disabled || !(u?.isAdmin || u?.isDev || u?.isModerator)) fail('permission-denied', 'Moderator access required.');
  }
  async function blocked(uid, c, tx) {
    const get = r => tx ? tx.get(r) : r.get();
    const others = [...new Set([c.targetUid, c.reporterUid].filter(Boolean))];
    const entries = await Promise.all(others.flatMap(other => [
      get(ref('uag_user_blocks', `${uid}_${other}`)), get(ref('uag_user_blocks', `${other}_${uid}`)),
    ]));
    return entries.some(s => s.exists);
  }
  async function clip(reportId, reporterUid, storagePath) {
    const prefix = `conduct_evidence/${reportId}/${reporterUid}/`;
    if (typeof storagePath !== 'string' || !storagePath.startsWith(prefix) ||
        storagePath.slice(prefix.length).includes('/') || !storagePath.endsWith('.mp4')) {
      fail('invalid-argument', 'Upload an MP4 clip for this report.');
    }
    try {
      const file = bucket.file(storagePath);
      const [m] = await file.getMetadata();
      if (m.contentType !== 'video/mp4' || !m.generation || Number(m.size) < 12 ||
          Number(m.size) > 25 * 1024 * 1024 || !Number.isFinite(Number(m.size))) throw Error('metadata');
      const [bytes] = await bucket.file(storagePath, { generation: m.generation }).download();
      if (bytes.toString('ascii', 4, 8) !== 'ftyp' || !hasVideoTrack(bytes)) throw Error('video');
      return { storagePath, storageGeneration: String(m.generation), contentHash: createHash('sha256').update(bytes).digest('hex') };
    } catch (_) { fail('failed-precondition', 'A readable MP4 video is required for review.'); }
  }
  function audit(tx, contractRef, action, uid, details = {}) {
    tx.set(contractRef.collection('incident_audit').doc(action), { action, actorUid: uid, ...details, createdAt: timestamp() });
  }
  async function recordBetrayal(request) {
    const uid = actor(request), sessionId = id(request.data?.sessionId);
    await eligible(uid, 'reportingRestricted');
    const caseId = key('betrayal', sessionId, uid), reportRef = ref('arc_raider_reports', caseId);
    const contractRef = ref('arc_raider_contracts', caseId), sessionRef = ref('trading_sessions', sessionId);
    return db.runTransaction(async tx => {
      const [session, prior] = await Promise.all([tx.get(sessionRef), tx.get(reportRef)]);
      const s = session.data();
      if (!s || ![s.traderOneUid, s.traderTwoUid].includes(uid)) fail('permission-denied', 'Trade participant required.');
      if (prior.exists) return { reportId: caseId, contractId: caseId };
      if (!['scheduled', 'ready', 'bothReady', 'inProgress', 'betrayal'].includes(s.status)) fail('failed-precondition', 'This trade cannot be flagged now.');
      const first = s.traderOneUid === uid, targetUid = first ? s.traderTwoUid : s.traderOneUid;
      if (!targetUid || targetUid === uid) fail('failed-precondition', 'A different trade partner is required.');
      const targetDisplayName = (first ? s.traderTwoName : s.traderOneName) || 'Raider';
      const at = timestamp();
      const provenance = { targetUid, targetDisplayName, reporterUid: uid, category: 'scam',
        creationSource: 'trading_betrayal', sourceSessionId: sessionId, incidentVerification: 'unverified' };
      tx.update(sessionRef, { [first ? 'traderOneMarkedBetrayal' : 'traderTwoMarkedBetrayal']: true, status: 'betrayal', updatedAt: at });
      tx.create(reportRef, { id: caseId, ...provenance, status: 'submitted', requestContract: true,
        description: 'Trading betrayal alleged. Evidence and moderator review required.', evidence: [],
        mapId: '', serverRegion: '', incidentAt: null, rewardItems: [], blueprintRewardCount: 0,
        blueprintRewardPool: [], createdAt: at, submittedAt: at, updatedAt: at, contractId: caseId });
      tx.create(contractRef, { id: caseId, ...provenance, reportId: caseId, status: 'pending',
        hunterUid: '', evidence: [], rewardItems: [], rewardSummary: '', blueprintRewardCount: 0,
        blueprintRewardPool: [], blueprintRewardSelection: [], blueprintRewardsSettled: false,
        createdAt: at, updatedAt: at, expiresAt: new Date(now().getTime() + 14 * DAY) });
      audit(tx, contractRef, 'allegation', uid, { reportId: caseId, sourceSessionId: sessionId });
      return { reportId: caseId, contractId: caseId };
    });
  }
  async function attachEvidence(request) {
    const uid = actor(request), reportId = id(request.data?.reportId);
    await eligible(uid, 'reportingRestricted');
    const r = await read('arc_raider_reports', reportId);
    if (!r || r.reporterUid !== uid) fail('permission-denied', 'Reporter access required.');
    const evidence = await clip(reportId, uid, request.data.storagePath);
    return db.runTransaction(async tx => {
      const reportRef = ref('arc_raider_reports', reportId), current = (await tx.get(reportRef)).data();
      const contractRef = current?.contractId ? ref('arc_raider_contracts', current.contractId) : null;
      const c = contractRef ? (await tx.get(contractRef)).data() : null;
      if (!current || current.reporterUid !== uid || !['submitted', 'pendingReview'].includes(current.status) || (c && expired(c, now()))) {
        fail('failed-precondition', 'This report is no longer awaiting evidence.');
      }
      tx.update(reportRef, { evidence: [{ ...evidence, id: key(evidence.storagePath), kind: 'video',
        submittedByUid: uid, url: '' }], status: 'pendingReview', updatedAt: timestamp() });
      if (contractRef) tx.update(contractRef, { status: 'verifying', updatedAt: timestamp() });
      return { status: 'pendingReview' };
    });
  }
  async function moderateReport(request) {
    const uid = actor(request), reportId = id(request.data?.reportId), approve = request.data?.approve === true;
    await moderator(uid);
    const r = await read('arc_raider_reports', reportId);
    if (!r) fail('not-found', 'Report not found.');
    const targetUid = r.targetUid || (approve ? id(request.data?.targetUid) : '');
    if (uid === r.reporterUid || uid === targetUid) fail('permission-denied', 'An independent moderator must review this report.');
    const notes = String(request.data?.notes || '').trim();
    if (!notes || notes.length > 1000) fail('invalid-argument', 'Provide review notes, up to 1000 characters.');
    let evidence;
    if (approve) {
      if (!targetUid || targetUid === r.reporterUid || !(await read('users', targetUid))) fail('failed-precondition', 'Identify a different canonical UAG account before activation.');
      await eligible(r.reporterUid, 'reportingRestricted');
      evidence = await clip(reportId, r.reporterUid, r.evidence?.[0]?.storagePath);
    }
    const contractId = r.contractId || key('report', reportId), contractRef = ref('arc_raider_contracts', contractId);
    return db.runTransaction(async tx => {
      const reportRef = ref('arc_raider_reports', reportId);
      const [rs, cs] = await Promise.all([tx.get(reportRef), tx.get(contractRef)]);
      const current = rs.data(), c = cs.data();
      const claimRef = approve ? ref('arc_verified_incident_claims', key(r.reporterUid, targetUid, evidence.contentHash)) : null;
      const claim = claimRef ? (await tx.get(claimRef)).data() : null;
      if (claim && claim.reportId !== reportId) fail('already-exists', 'This evidence already supports a report against this account.');
      if (current.status === (approve ? 'approved' : 'rejected')) return { contractId, status: c?.status || current.status };
      if (!['submitted', 'pendingReview'].includes(current.status) || (c && expired(c, now())) ||
          current.reporterUid !== r.reporterUid || current.targetUid !== r.targetUid ||
          (approve && current.evidence?.[0]?.storagePath !== evidence.storagePath)) fail('failed-precondition', 'Report changed or expired; review it again.');
      const at = timestamp();
      if (claimRef && !claim) tx.create(claimRef, { reportId });
      tx.update(reportRef, { status: approve ? 'approved' : 'rejected', targetUid,
        incidentVerification: approve ? 'verified' : 'rejected', moderationNotes: notes,
        moderatedByUid: uid, moderatedAt: at, updatedAt: at, contractId,
        ...(approve ? { verifiedEvidence: evidence } : {}) });
      if (approve && current.requestContract) {
        const count = Number(current.blueprintRewardCount || 0), pool = current.blueprintRewardPool || [];
        if (!Number.isInteger(count) || count < 0 || count > pool.length) fail('failed-precondition', 'Invalid reward offer.');
        const rewardItems = current.rewardItems || [];
        const rewardSummary = [...rewardItems.map(e => `${e.quantity}× ${e.name}`),
          ...(count ? [`${count}× Blueprint dupe choice`] : [])].join(' • ');
        tx.set(contractRef, { ...(c || {}), id: contractId, reportId, targetUid,
          targetDisplayName: current.targetDisplayName, targetGameIdentity: current.targetGameIdentity || '',
          reporterUid: current.reporterUid, hunterUid: '', category: current.category || 'other',
          creationSource: current.creationSource || 'moderated_report', sourceSessionId: current.sourceSessionId || '',
          incidentVerification: 'verified', status: 'available', rewardItems, rewardSummary,
          blueprintRewardCount: count, blueprintRewardPool: pool, blueprintRewardSelection: [],
          blueprintRewardsSettled: false, reputationReward: 10, evidence: [],
          evidenceRequirements: 'Provide an MP4 video identifying the encounter and outcome.',
          createdAt: c?.createdAt || at, updatedAt: at, expiresAt: new Date(now().getTime() + 14 * DAY) });
        audit(tx, contractRef, 'incident_verified', uid, { reportId, notes, ...evidence });
      } else if (c) {
        tx.update(contractRef, { status: 'rejected', updatedAt: at, resolvedAt: at });
        audit(tx, contractRef, 'incident_rejected', uid, { notes });
      }
      return { contractId, status: approve ? 'available' : 'rejected' };
    });
  }
  async function intelligence(targetUid) {
    // Query only inside Admin SDK. Derived object is ephemeral and cannot go
    // stale in storage; its rolling window is configurable without a migration.
    const reports = await db.collection('arc_raider_reports').where('targetUid', '==', targetUid).get();
    return deriveIntelligence(reports.docs.map(d => d.data()), now(), windowDays);
  }
  async function discover(request) {
    const uid = actor(request);
    await eligible(uid, 'huntingRestricted');
    const search = String(request.data?.search || '').trim().toLowerCase().slice(0, 100);
    const profile = (await ref('users', uid).collection('trading_activity').doc('profile').get()).data();
    const contracts = await db.collection('arc_raider_contracts').where('status', '==', 'available').get();
    const result = [];
    for (const doc of contracts.docs) {
      const c = doc.data();
      // Exclude by authenticated canonical identity BEFORE matching any alias.
      if (!canDiscover(c, uid, now()) || await blocked(uid, c)) continue;
      if (search && ![c.targetUid, c.targetDisplayName, c.targetGameIdentity].some(v => String(v || '').toLowerCase().includes(search))) continue;
      const intel = await intelligence(c.targetUid);
      result.push(hunterProjection(doc.id, c, intel, profile?.serverPreference));
    }
    result.sort((a, b) => Number(b.regionMatch === 'STRONG') - Number(a.regionMatch === 'STRONG') || a.id.localeCompare(b.id));
    return { contracts: result.slice(0, 100), state: result.length ? 'ready' : 'noEligibleContracts' };
  }
  async function accept(request) {
    const uid = actor(request), contractId = id(request.data?.contractId);
    await eligible(uid, 'huntingRestricted');
    return db.runTransaction(async tx => {
      const contractRef = ref('arc_raider_contracts', contractId), c = (await tx.get(contractRef)).data();
      if (!c || !canDiscover(c, uid, now()) || await blocked(uid, c, tx)) fail('permission-denied', 'This Contract is not available to this account.');
      tx.update(contractRef, { hunterUid: uid, status: 'accepted', acceptedAt: timestamp(), updatedAt: timestamp() });
      audit(tx, contractRef, 'accepted', uid);
      return { status: 'accepted' };
    });
  }
  async function accountStatus(request) {
    const uid = actor(request);
    const contracts = await db.collection('arc_raider_contracts').where('targetUid', '==', uid).get();
    return { cases: contracts.docs.map(d => targetProjection(d.id, d.data(), now())) };
  }
  async function challenge(request) {
    const uid = actor(request), contractId = id(request.data?.contractId);
    const reason = String(request.data?.reason || '').trim();
    if (reason.length < 10 || reason.length > 1000) fail('invalid-argument', 'Explain your challenge in 10–1000 characters.');
    return db.runTransaction(async tx => {
      const contractRef = ref('arc_raider_contracts', contractId), c = (await tx.get(contractRef)).data();
      if (!c || c.targetUid !== uid) fail('permission-denied', 'Account case access required.');
      if (c.challengeStatus) return { status: c.challengeStatus };
      if (!targetProjection(contractId, c, now()).canChallenge) fail('failed-precondition', 'This case is already closed.');
      tx.create(ref('arc_contract_challenges', contractId), { contractId, reportId: c.reportId, targetUid: uid, reason, status: 'pending', createdAt: timestamp() });
      tx.update(contractRef, { challengeStatus: 'pending', updatedAt: timestamp() });
      audit(tx, contractRef, 'challenged', uid);
      return { status: 'pending' };
    });
  }
  async function reviewChallenge(request) {
    const uid = actor(request), contractId = id(request.data?.contractId);
    await moderator(uid);
    const overturn = request.data?.overturn === true, notes = String(request.data?.notes || '').trim();
    if (!notes || notes.length > 1000) fail('invalid-argument', 'Provide review notes.');
    return db.runTransaction(async tx => {
      const contractRef = ref('arc_raider_contracts', contractId), challengeRef = ref('arc_contract_challenges', contractId);
      const [cs, qs, result] = await Promise.all([tx.get(contractRef), tx.get(challengeRef), tx.get(ref('raider_verified_results', contractId))]);
      const c = cs.data(), q = qs.data();
      if (!c || !q || q.status !== 'pending') fail('failed-precondition', 'No pending challenge.');
      if ([c.targetUid, c.reporterUid, c.hunterUid].includes(uid)) fail('permission-denied', 'Independent moderator required.');
      const status = overturn ? 'overturned' : 'upheld';
      tx.update(challengeRef, { status, notes, reviewedByUid: uid, reviewedAt: timestamp() });
      tx.update(contractRef, { challengeStatus: status, ...(overturn ? { status, incidentVerification: 'overturned', resolvedAt: timestamp() } : {}), updatedAt: timestamp() });
      if (overturn) {
        tx.update(ref('arc_raider_reports', c.reportId), { status: 'overturned', incidentVerification: 'overturned', updatedAt: timestamp() });
        if (result.exists) tx.update(ref('raider_verified_results', contractId), { verificationStatus: 'overturned', overturnedAt: timestamp() });
      }
      audit(tx, contractRef, `challenge_${status}`, uid, { notes });
      return { status };
    });
  }
  async function adminContext(request) {
    const uid = actor(request), reportId = id(request.data?.reportId);
    await moderator(uid);
    const r = await read('arc_raider_reports', reportId);
    if (!r || r.targetUid === uid) fail('permission-denied', 'Independent moderation access required.');
    const contractId = r.contractId || key('report', reportId);
    const c = await read('arc_raider_contracts', contractId);
    const intel = r.targetUid ? await intelligence(r.targetUid) : deriveIntelligence([], now(), windowDays);
    const history = await ref('arc_raider_contracts', contractId).collection('incident_audit').get();
    return { reportId, contractId, targetUid: r.targetUid || '', source: r.creationSource || 'manual_report',
      sourceSessionId: r.sourceSessionId || '', incidentVerification: r.incidentVerification || 'unverified',
      contractStatus: c ? effectiveStatus(c, now()) : 'not_created',
      intelligence: { mapAffinity: intel.mapAffinity, confidence: intel.confidence, verifiedIncidentCount: intel.verifiedIncidentCount },
      history: history.docs.map(d => ({ action: d.data().action, notes: d.data().notes || '' })) };
  }
  async function lifecycleChanged(event) {
    const before = event.data?.before?.data(), after = event.data?.after?.data();
    if (!after || before?.status === after.status) return;
    const contractRef = event.data.after.ref;
    await contractRef.collection('incident_audit').doc(key('lifecycle', event.id)).set({
      action: `status_${after.status}`, previousStatus: before?.status || '', createdAt: timestamp(), actorUid: 'system' });
  }
  async function expireContracts() {
    const snapshot = await db.collection('arc_raider_contracts').where('expiresAt', '<=', now()).get();
    for (const doc of snapshot.docs) await db.runTransaction(async tx => {
      const c = (await tx.get(doc.ref)).data();
      if (c && !terminal.has(c.status) && expired(c, now())) {
        tx.update(doc.ref, { status: 'expired', resolvedAt: timestamp(), updatedAt: timestamp() });
        audit(tx, doc.ref, 'expired', 'system');
      }
    });
  }
  async function reportWithdrawn(event) {
    const r = event.data?.after?.data();
    if (r?.status !== 'withdrawn' || !r.contractId) return;
    const contractRef = ref('arc_raider_contracts', r.contractId);
    await db.runTransaction(async tx => {
      const c = (await tx.get(contractRef)).data();
      if (c && ['pending', 'verifying'].includes(c.status)) {
        tx.update(contractRef, { status: 'cancelled', updatedAt: timestamp() });
        audit(tx, contractRef, 'withdrawn', r.reporterUid);
      }
    });
  }
  return { recordBetrayal, attachEvidence, moderateReport, discover, accept, accountStatus, challenge, reviewChallenge, expireContracts, reportWithdrawn, adminContext, lifecycleChanged };
}
module.exports = { createRaiderContractIntelligence, deriveIntelligence, hunterProjection, targetProjection, canDiscover, effectiveStatus };