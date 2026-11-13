'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { ref: storageRef, uploadBytes, getBytes } = require('firebase/storage');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
async function run() {
  const env = await initializeTestEnvironment({ projectId: 'demo-raider-contracts', firestore: {
    rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: fs.readFileSync(path.resolve(__dirname, '../storage.rules'), 'utf8'), host: '127.0.0.1', port: 9199 } });
  let checks = 0;
  const yes = async p => { await assertSucceeds(p); checks++; };
  const no = async p => { await assertFails(p); checks++; };
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      for (const uid of ['target', 'hunter', 'issuer', 'other', 'mod']) await db.doc(`users/${uid}`).set({ ageVerification: { verifiedOver18: true }, ...(uid === 'mod' ? { isModerator: true } : {}) });
      for (const [id, state] of [['active','available'],['assigned','accepted'],['pending','pending']]) await db.doc(`arc_raider_contracts/${id}`).set({
        id, status: state, targetUid: 'target', reporterUid: 'issuer', hunterUid: state === 'accepted' ? 'hunter' : '',
        blueprintRewardPool: [], blueprintRewardCount: 0, evidence: [] });
      await db.doc('arc_raider_reports/r').set({ reporterUid: 'issuer', targetUid: 'target', status: 'submitted' });
      await db.doc('arc_raider_contracts/active/incident_audit/a').set({ action: 'incident_verified' });
      await db.doc('arc_raider_contracts/assigned/verification_audit/a').set({ hunterUid: 'hunter' });
      await db.doc('raider_verified_results/assigned').set({ hunterUid: 'hunter', issuerUid: 'issuer', verificationStatus: 'verified' });
      await db.doc('arc_target_intelligence/target').set({ activityHourBuckets: { 3: 10 } });
      await db.doc('arc_contract_challenges/active').set({ targetUid: 'target', status: 'pending' });
      await uploadBytes(storageRef(context.storage(), 'contract_evidence/assigned/hunter/clip.mp4'), new Uint8Array(16), { contentType: 'video/mp4' });
    });
    const db = uid => env.authenticatedContext(uid).firestore();
    const target = db('target'), hunter = db('hunter'), issuer = db('issuer'), other = db('other'), mod = db('mod');
    for (const account of [target, other, hunter]) await no(account.doc('arc_raider_contracts/active').get());
    for (const identifier of ['targetUid', 'targetDisplayName', 'targetGameIdentity']) await no(target.collection('arc_raider_contracts').where(identifier, '==', 'target').get());
    await no(target.collection('arc_raider_contracts').where('status', '==', 'available').get());
    await yes(issuer.doc('arc_raider_contracts/active').get());
    await yes(hunter.doc('arc_raider_contracts/assigned').get());
    await yes(mod.doc('arc_raider_contracts/active').get());
    await yes(hunter.collection('arc_raider_contracts').where('hunterUid', '==', 'hunter').where('targetUid', '!=', 'hunter').get());
    await yes(issuer.collection('arc_raider_contracts').where('reporterUid', '==', 'issuer').where('targetUid', '!=', 'issuer').get());
    await no(hunter.doc('arc_raider_contracts/active').update({ status: 'accepted', hunterUid: 'hunter', acceptedAt: new Date(), updatedAt: new Date() }));
    await no(mod.doc('arc_raider_contracts/pending').update({ status: 'available' }));
    await no(mod.doc('arc_raider_contracts/new').set({ status: 'available', hunterUid: '', evidence: [] }));
    await yes(hunter.doc('arc_raider_contracts/assigned').update({ status: 'inProgress', updatedAt: new Date() }));
    await no(target.doc('arc_raider_contracts/assigned').get());
    await no(target.doc('raider_verified_results/assigned').get());
    await no(other.doc('raider_verified_results/assigned').get());
    await yes(hunter.doc('raider_verified_results/assigned').get());
    await no(target.doc('arc_raider_contracts/assigned/verification_audit/a').get());
    await yes(hunter.doc('arc_raider_contracts/assigned/verification_audit/a').get());
    await no(target.doc('arc_raider_contracts/active/incident_audit/a').get());
    await yes(mod.doc('arc_raider_contracts/active/incident_audit/a').get());
    for (const account of [target, hunter, mod]) await no(account.doc('arc_target_intelligence/target').get());
    await no(target.doc('arc_contract_challenges/active').get());
    await no(target.doc('arc_contract_challenges/active').set({ status: 'upheld' }));
    await yes(mod.doc('arc_contract_challenges/active').get());
    await no(target.doc('arc_contract_restrictions/target').set({ huntingRestricted: false }));
    await yes(mod.doc('arc_contract_restrictions/target').set({ huntingRestricted: true }));
    await no(issuer.doc('arc_raider_reports/r').update({ status: 'approved', incidentVerification: 'verified' }));
    await no(mod.doc('arc_raider_reports/r').update({ status: 'approved' }));
    await no(issuer.doc('arc_raider_reports/r').update({ status: 'withdrawn', targetUid: 'other' }));
    await yes(issuer.doc('arc_raider_reports/r').update({ status: 'withdrawn', updatedAt: new Date() }));
    await no(issuer.doc('arc_raider_reports/forged').set({ reporterUid: 'issuer', status: 'submitted', creationSource: 'trading_betrayal' }));
    await yes(issuer.doc('arc_raider_reports/manual').set({ reporterUid: 'issuer', targetUid: '', status: 'submitted' }));
    await no(env.unauthenticatedContext().firestore().doc('arc_raider_contracts/active').get());
    for (const uid of ['target', 'other']) await no(getBytes(storageRef(env.authenticatedContext(uid).storage(), 'contract_evidence/assigned/hunter/clip.mp4')));
    for (const uid of ['hunter', 'issuer', 'mod']) await yes(getBytes(storageRef(env.authenticatedContext(uid).storage(), 'contract_evidence/assigned/hunter/clip.mp4')));
    await no(uploadBytes(storageRef(env.authenticatedContext('target').storage(), 'contract_evidence/assigned/target/new.mp4'), new Uint8Array(16), { contentType: 'video/mp4' }));
    // Real Firestore transactions exercise the deployed handler code (media and
    // Auth lookups injected); this catches sentinel/array and transaction errors.
    const admin = require('firebase-admin');
    const app = admin.initializeApp({ projectId: 'demo-raider-contracts' }, 'contract-integration');
    try {
      const backendDb = app.firestore();
      await backendDb.doc('arc_contract_restrictions/target').delete();
      await backendDb.doc('trading_sessions/server_flow').set({ traderOneUid: 'issuer', traderTwoUid: 'target', traderTwoName: 'Raider', status: 'ready' });
      const atom = (type, body) => { const head = Buffer.alloc(8); head.writeUInt32BE(body.length + 8); head.write(type, 4); return Buffer.concat([head, body]); };
      const handler = Buffer.alloc(12); handler.write('vide', 8);
      const bytes = Buffer.concat([atom('ftyp', Buffer.from('isom0000')), atom('moov', atom('trak', atom('mdia', atom('hdlr', handler))))]);
      class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
      const dependencies = { db: backendDb, HttpsError, timestamp: () => admin.firestore.FieldValue.serverTimestamp(), getAuthUser: async () => ({ disabled: false }),
        bucket: { file: () => ({ getMetadata: async () => [{ contentType: 'video/mp4', generation: '1', size: bytes.length }], download: async () => [bytes] }) } };
      const api = require('../functions/raider_contract_intelligence').createRaiderContractIntelligence(dependencies);
      const verification = require('../functions/raider_contract_verification').createContractVerification(dependencies);
      const req = (uid, data) => ({ auth: { uid }, data });
      const ids = await api.recordBetrayal(req('issuer', { sessionId: 'server_flow' })); checks++;
      await api.attachEvidence(req('issuer', { reportId: ids.reportId, storagePath: `conduct_evidence/${ids.reportId}/issuer/clip.mp4` })); checks++;
      await api.moderateReport(req('mod', { reportId: ids.reportId, approve: true, notes: 'Verified incident and identity in video.' })); checks++;
      const assert = require('node:assert/strict');
      assert.equal((await api.discover(req('hunter', {}))).contracts.length, 1); checks++;
      assert.equal((await api.discover(req('target', {}))).contracts.length, 0); checks++;
      const context = await api.adminContext(req('mod', { reportId: ids.reportId }));
      assert.equal(context.source, 'trading_betrayal'); checks++;
      await api.accept(req('hunter', { contractId: ids.contractId })); checks++;
      await yes(hunter.doc(`arc_raider_contracts/${ids.contractId}`).update({ status: 'inProgress', updatedAt: new Date() }));
      await verification.submit(req('hunter', { contractId: ids.contractId, submissionId: 'clip', storagePath: `contract_evidence/${ids.contractId}/hunter/clip.mp4` })); checks++;
      await verification.review(req('issuer', { contractId: ids.contractId, submissionId: 'clip', decision: 'confirm' })); checks++;
      assert.equal((await api.accountStatus(req('target', {}))).cases.find(c => c.id === ids.contractId).status, 'completed'); checks++;
      await api.challenge(req('target', { contractId: ids.contractId, reason: 'The evidence identifies a different account.' })); checks++;
      await api.reviewChallenge(req('mod', { contractId: ids.contractId, overturn: true, notes: 'Identity mismatch confirmed.' })); checks++;
      assert.equal((await backendDb.doc(`raider_verified_results/${ids.contractId}`).get()).data().verificationStatus, 'overturned'); checks++;
    } finally { await app.delete(); }
    console.log(`Raider Contract rules: ${checks} checks passed`);
  } finally { await env.cleanup(); }
}
run().catch(e => { console.error(e); process.exitCode = 1; });