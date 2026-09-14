'use strict';

const countryCodes = new Set(('AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW').split(' '));

function hasVideoTrack(bytes) {
  function boxes(start, end, depth) {
    if (depth > 8) return false;
    for (let at = start; at + 8 <= end;) {
      let size = bytes.readUInt32BE(at);
      const type = bytes.toString('ascii', at + 4, at + 8);
      let header = 8;
      if (size === 1) {
        if (at + 16 > end) return false;
        const large = bytes.readBigUInt64BE(at + 8);
        if (large > BigInt(bytes.length)) return false;
        size = Number(large); header = 16;
      } else if (size === 0) size = end - at;
      if (size < header || at + size > end) return false;
      if (type === 'hdlr' && depth === 3 && size >= header + 12 &&
          bytes.toString('ascii', at + header + 8, at + header + 12) === 'vide') return true;
      const expected = ['moov', 'trak', 'mdia'][depth];
      if (type === expected && boxes(at + header, at + size, depth + 1)) return true;
      at += size;
    }
    return false;
  }
  return boxes(0, bytes.length, 0);
}

// Dependencies are injected so the real transactional authority can be tested.
function createContractVerification({ db, bucket, timestamp, HttpsError, now = () => new Date() }) {
  const fail = (code, message) => { throw new HttpsError(code, message); };
  const token = (value, label) => {
    if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
      fail('invalid-argument', `Invalid ${label}.`);
    }
    return value;
  };
  function input(request) {
    if (!request.auth?.uid) fail('unauthenticated', 'Sign in required.');
    const data = request.data || {};
    return { ...data, contractId: token(data.contractId, 'contract ID'),
      submissionId: token(data.submissionId, 'submission ID'), uid: request.auth.uid };
  }
  function contract(snapshot) {
    if (!snapshot.exists) fail('not-found', 'Contract not found.');
    return snapshot.data();
  }
  async function video(path, contractId, hunterUid, submissionId) {
    if (path !== `contract_evidence/${contractId}/${hunterUid}/${submissionId}.mp4`) {
      fail('invalid-argument', 'Evidence must be an immutable clip uploaded for this contract.');
    }
    let metadata, bytes;
    try {
      const file = bucket.file(path);
      [metadata] = await file.getMetadata();
      if (metadata.contentType !== 'video/mp4' || !Number.isFinite(Number(metadata.size)) || !metadata.generation || Number(metadata.size) < 12 ||
          Number(metadata.size) > 25 * 1024 * 1024) {
        fail('failed-precondition', 'Evidence must be an MP4 clip of at most 25 MB.');
      }
      [bytes] = await file.download();
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      fail('failed-precondition', 'The evidence clip is unavailable.');
    }
    if (bytes.length < 12 || bytes.toString('ascii', 4, 8) !== 'ftyp' ||
        !['isom', 'iso2', 'mp41', 'mp42', 'avc1', 'M4V ', 'MSNV', 'dash'].includes(bytes.toString('ascii', 8, 12)) ||
        !hasVideoTrack(bytes)) {
      fail('failed-precondition', 'Evidence does not have a supported MP4 signature.');
    }
    return String(metadata.generation || '');
  }
  async function submit(request) {
    const d = input(request);
    const ref = db.collection('arc_raider_contracts').doc(d.contractId);
    const initial = contract(await ref.get());
    if (initial.hunterUid !== d.uid || initial.reporterUid === d.uid) {
      fail('permission-denied', 'Only the assigned hunter may submit evidence.');
    }
    const generation = await video(d.storagePath, d.contractId, d.uid, d.submissionId);
    return db.runTransaction(async tx => {
      const c = contract(await tx.get(ref));
      if (c.hunterUid !== d.uid || c.reporterUid === d.uid) fail('permission-denied', 'Hunter assignment changed.');
      if (c.evidenceSubmissionId === d.submissionId) {
        if (c.evidence?.[0]?.storagePath !== d.storagePath) fail('already-exists', 'Submission ID already used.');
        return { status: c.status, verificationStatus: c.verificationStatus, submissionId: d.submissionId };
      }
      if (!(c.status === 'inProgress' || (c.status === 'evidenceSubmitted' && c.verificationStatus === 'rejected'))) {
        fail('failed-precondition', 'Evidence cannot be changed in this state.');
      }
      const audit = ref.collection('verification_audit').doc(`submission_${d.submissionId}`);
      if ((await tx.get(audit)).exists) fail('already-exists', 'Submission ID cannot be reused.');
      const at = timestamp();
      tx.update(ref, { status: 'evidenceSubmitted', verificationStatus: 'pending',
        evidenceSubmissionId: d.submissionId, evidence: [{ id: d.submissionId,
          submittedByUid: d.uid, kind: 'video', storagePath: d.storagePath,
          storageGeneration: generation, url: '', createdAt: at }],
        evidenceSubmittedAt: at, updatedAt: at, verifiedAt: null, verifiedByUid: '',
        rejectedAt: null, rejectionReason: '' });
      tx.create(audit, { action: 'submitted', actorUid: d.uid, submissionId: d.submissionId,
        storagePath: d.storagePath, storageGeneration: generation, createdAt: at });
      return { status: 'evidenceSubmitted', verificationStatus: 'pending', submissionId: d.submissionId };
    });
  }
  async function review(request) {
    const d = input(request);
    if (!['confirm', 'reject'].includes(d.decision)) fail('invalid-argument', 'Invalid review decision.');
    const reason = typeof d.reason === 'string' ? d.reason.trim() : '';
    if (reason.length > 1000 || (d.decision === 'reject' && !reason)) fail('invalid-argument', 'Provide a rejection reason of at most 1000 characters.');
    const ref = db.collection('arc_raider_contracts').doc(d.contractId);
    const initial = contract(await ref.get());
    const issuer = c => {
      if (c.reporterUid !== d.uid || !c.hunterUid || c.hunterUid === d.uid || c.hunterUid === c.targetUid) {
        fail('permission-denied', 'Only the original issuer may review this hunter.');
      }
      if (c.evidenceSubmissionId !== d.submissionId) fail('failed-precondition', 'Evidence changed; review the latest submission.');
    };
    issuer(initial);
    const clip = initial.evidence?.[0];
    if (!clip || clip.kind !== 'video' || clip.submittedByUid !== initial.hunterUid) fail('failed-precondition', 'Hunter video evidence is required.');
    const generation = await video(clip.storagePath, d.contractId, initial.hunterUid, d.submissionId);
    if (generation !== clip.storageGeneration) fail('failed-precondition', 'Evidence object changed.');
    return db.runTransaction(async tx => {
      const c = contract(await tx.get(ref));
      issuer(c);
      if (c.hunterUid !== initial.hunterUid || c.evidence?.[0]?.storagePath !== clip.storagePath ||
          c.evidence?.[0]?.storageGeneration !== generation) fail('failed-precondition', 'Evidence changed.');
      const resultRef = db.collection('raider_verified_results').doc(d.contractId);
      const result = await tx.get(resultRef);
      if (d.decision === 'confirm' && c.status === 'completed' && c.verificationStatus === 'verified' &&
          c.verifiedByUid === d.uid && result.exists && result.data().submissionId === d.submissionId) {
        return { status: 'completed', verificationStatus: 'verified', submissionId: d.submissionId };
      }
      if (d.decision === 'reject' && c.status === 'evidenceSubmitted' && c.verificationStatus === 'rejected') {
        return { status: c.status, verificationStatus: c.verificationStatus, submissionId: d.submissionId };
      }
      if (c.status !== 'evidenceSubmitted' || c.verificationStatus !== 'pending' || result.exists) fail('failed-precondition', 'This submission is no longer awaiting review.');
      const hunter = d.decision === 'confirm' ? await tx.get(db.collection('users').doc(c.hunterUid)) : null;
      const at = timestamp();
      const verified = d.decision === 'confirm';
      tx.update(ref, { status: verified ? 'completed' : 'evidenceSubmitted',
        verificationStatus: verified ? 'verified' : 'rejected',
        verifiedByUid: verified ? d.uid : '', verifiedAt: verified ? at : null,
        rejectedAt: verified ? null : at, rejectionReason: verified ? '' : reason,
        updatedAt: at, ...(verified ? { resolvedAt: at } : {}) });
      tx.create(ref.collection('verification_audit').doc(`review_${d.submissionId}`), {
        action: verified ? 'verified' : 'rejected', actorUid: d.uid,
        submissionId: d.submissionId, reason, createdAt: at });
      if (verified) {
        const country = hunter?.data()?.countryCode;
        tx.create(resultRef, { contractId: d.contractId, submissionId: d.submissionId,
          hunterUid: c.hunterUid, issuerUid: d.uid, verifiedByUid: d.uid,
          evidenceSubmissionId: d.submissionId, verificationStatus: 'verified',
          countryCode: countryCodes.has(country) ? country : '',
          month: now().toISOString().slice(0, 7), verifiedAt: at, createdAt: at });
      }
      return { status: verified ? 'completed' : 'evidenceSubmitted',
        verificationStatus: verified ? 'verified' : 'rejected', submissionId: d.submissionId };
    });
  }
  return { submit, review };
}
module.exports = { createContractVerification, hasVideoTrack };
