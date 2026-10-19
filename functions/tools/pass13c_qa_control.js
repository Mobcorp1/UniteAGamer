'use strict';
// Operator-only QA control. Run from project root with ADC already configured.
// Never supply Firebase credentials or tokens via chat. No public enable operation.
const admin = require('firebase-admin');
const {controlValid, qaPairAllowed} = require('../uag_pass13c_qa_guard');
const PROJECT = 'unite-a-gamer';
const argv = process.argv.slice(2);
const mode = argv[0];
const get = (flag) => {
  const index = argv.indexOf(flag);
  return index < 0 ? '' : (argv[index+1] || '');
};
function fail(reason) { throw new Error(`PASS13C_QA_STOP: ${reason}`); }
const project = get('--project');
if (project !== PROJECT) fail(`Explicit --project ${PROJECT} required`);
if (!['audit','enable','disable'].includes(mode)) fail('Mode must be audit, enable or disable');
// Prevent accidental writes from an admin shell pointed at another project.
const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (credentialsPath) {
  const fs=require('fs');
  const config=JSON.parse(fs.readFileSync(credentialsPath,'utf8'));
  if (config.project_id && config.project_id !== PROJECT) fail('ADC credential project mismatch');
}
admin.initializeApp({credential:admin.credential.applicationDefault(),projectId:PROJECT});
const db=admin.firestore();
const ref=db.collection('uag_release_controls').doc('launch_matching');
const mask = (uid) => `${uid.slice(0,2)}…${uid.slice(-4)}`;
(async()=>{
  if (mode === 'enable') {
    const testers=get('--testers').split(',').map(s=>s.trim()).filter(Boolean);
    const hours=Number(get('--hours') || '24');
    if (!Number.isInteger(hours) || hours < 1 || hours > 48) fail('QA hours must be an integer 1-48');
    if (get('--confirm') !== 'QA_TESTERS_ONLY') fail('Explicit --confirm QA_TESTERS_ONLY required');
    const ends=new Date(Date.now()+hours*3600000);
    const setting={enabled:true,qaMode:'testers',publicEnabled:false,tradeAlertsEnabled:true,
      squadAlertsEnabled:true,testerUids:testers,qaExpiresAt:ends};
    if (!controlValid(setting,'tradeAlertsEnabled') || !controlValid(setting,'squadAlertsEnabled'))
      fail('Invalid tester IDs or expiry');
    for(const uid of testers) {
      const [account, userDoc]=await Promise.all([admin.auth().getUser(uid), db.collection('users').doc(uid).get()]);
      if (account.disabled || userDoc.data()?.ageVerification?.verifiedOver18 !== true)
        fail(`Tester ${mask(uid)} is disabled or not age-verified`);
    }
    const current=(await ref.get()).data() || {};
    if (current.publicEnabled === true || current.qaMode === 'public')
      fail('Existing public control must be disabled before QA mode');
    await ref.set({...setting,qaExpiresAt:admin.firestore.Timestamp.fromDate(ends),
      qaConfiguredAt:admin.firestore.FieldValue.serverTimestamp()}, {merge:true});
    console.log('PASS 13C QA ACTIVE: only',testers.map(mask).join(', '),'expires in',hours,'hours.');
    return;
  }
  if (mode === 'disable') {
    if (get('--confirm') !== 'STOP_QA') fail('Explicit --confirm STOP_QA required');
    await ref.set({enabled:false,tradeAlertsEnabled:false,squadAlertsEnabled:false,publicEnabled:false,
      qaMode:'disabled',testerUids:[],qaExpiresAt:admin.firestore.Timestamp.fromDate(new Date(0)),
      qaStoppedAt:admin.firestore.FieldValue.serverTimestamp()}, {merge:true});
    console.log('PASS 13C QA DISABLED');
    return;
  }
  const record=(await ref.get()).data() || {};
  console.log('PASS 13C RELEASE CONTROL',JSON.stringify({
    enabled:record.enabled===true,qaMode:record.qaMode || 'none',
    publicEnabled:record.publicEnabled===true,tradeAlertsEnabled:record.tradeAlertsEnabled===true,
    squadAlertsEnabled:record.squadAlertsEnabled===true,
    activeNow:controlValid(record,'tradeAlertsEnabled') || controlValid(record,'squadAlertsEnabled'),
    testers:Array.isArray(record.testerUids)?record.testerUids.map(mask):[],
    expiry:record.qaExpiresAt?.toDate?.().toISOString?.() || null,
  },null,2));
})().catch((err)=>{console.error('PASS 13C QA CONTROL FAILED:',err.message);process.exitCode=1;});
