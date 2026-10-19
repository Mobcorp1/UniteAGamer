'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { controlValid, qaPairAllowed, qaMemberAllowed, canDeliver } = require('../uag_pass13c_qa_guard');
const now=Date.now();
const ids=['tester_AAAAAAAAAA','tester_BBBBBBBBBB'];
const fixture={enabled:true,qaMode:'testers',publicEnabled:false,tradeAlertsEnabled:true,squadAlertsEnabled:true,
  testerUids:ids,qaExpiresAt:new Date(now+2*86400000)};
test('default off, public mode rejected, no tester bypass', () => {
  assert.equal(controlValid({},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,qaMode:'public'},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,publicEnabled:true},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,testerUids:[]},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,testerUids:[ids[0],ids[0]]},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,qaExpiresAt:new Date(now-10)},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,qaExpiresAt:new Date(now+30*86400000)},'tradeAlertsEnabled',now),false);
  assert.equal(controlValid({...fixture,enabled:false},'tradeAlertsEnabled',now),false);
});
test('two explicitly listed, distinct testers only', () => {
  assert.equal(qaPairAllowed(fixture,ids[0],ids[1],'squadAlertsEnabled',now),true);
  assert.equal(qaPairAllowed(fixture,ids[0],'other_user_999','squadAlertsEnabled',now),false);
  assert.equal(qaPairAllowed(fixture,ids[0],ids[0],'squadAlertsEnabled',now),false);
  assert.equal(qaMemberAllowed(fixture,ids[0],'tradeAlertsEnabled',now),true);
  assert.equal(qaMemberAllowed(fixture,'other_user_999','tradeAlertsEnabled',now),false);
});
function makeDb(data) {
  return {collection: (name) => ({doc: (id) => ({
    collection: (sub) => ({doc: (x) => ({get:async()=>({exists:true,data:()=>data[`${name}/${id}/${sub}/${x}`]??{}})})}),
    get:async()=>{
      const key=`${name}/${id}`;return {exists:Object.hasOwn(data,key),data:()=>data[key]};
    },
  })})};
}
const admin={auth:()=>({getUser:async()=>({disabled:false})})};
function baseDb() {
 const d={
  'uag_release_controls/launch_matching':fixture,
  [`users/${ids[0]}`]:{ageVerification:{verifiedOver18:true}},
  [`users/${ids[1]}`]:{ageVerification:{verifiedOver18:true}},
  [`users/${ids[0]}/notification_preferences/current`]:{watchesAndQueues:true,matchmaking:true},
  [`users/${ids[1]}/notification_preferences/current`]:{watchesAndQueues:true,matchmaking:true},
  'arc_blueprint_watches/watch_abcdef12345':{ownerUid:ids[0],type:'blueprint',active:true,notificationsEnabled:true,
    notificationPreference:'immediate',blueprintId:'ferro'},
  'trading_listings/list_abcdef12345':{ownerUid:ids[1],active:true,expiresAt:new Date(now+86400000),offeredTradeItemIds:['ferro']},
 };
 return d;
}
const notification={pass13Discovery:true,type:'watch_match',targetUid:ids[0],actorUid:ids[1],watchId:'watch_abcdef12345',listingId:'list_abcdef12345'};
test('live watch may dispatch; expired listing cannot',async()=>{
 let d=baseDb();assert.equal(await canDeliver(makeDb(d),admin,notification,now),true);
 d['trading_listings/list_abcdef12345'].expiresAt=new Date(now-1000);
 assert.equal(await canDeliver(makeDb(d),admin,notification,now),false);
});
test('muted watch, cancelled listing, revoked prefs and blocks fail closed',async()=>{
 const d=baseDb();d['arc_blueprint_watches/watch_abcdef12345'].notificationPreference='muted';
 assert.equal(await canDeliver(makeDb(d),admin,notification,now),false);
 d['arc_blueprint_watches/watch_abcdef12345'].notificationPreference='immediate';
 d[`users/${ids[0]}/notification_preferences/current`].watchesAndQueues=false;
 assert.equal(await canDeliver(makeDb(d),admin,notification,now),false);
 d[`users/${ids[0]}/notification_preferences/current`].watchesAndQueues=true;
 d[`uag_user_blocks/${ids[0]}_${ids[1]}`]={blockerUid:ids[0]};
 assert.equal(await canDeliver(makeDb(d),admin,notification,now),false);
});
test('attempt to send to non-tester always refused', async()=>{
 const d=baseDb();assert.equal(await canDeliver(makeDb(d),admin,{...notification,targetUid:'outsider_AAAAAAAA'},now),false);
});
test('squad alert requires both active and fresh; post-event expiration fails',async()=>{
 const d=baseDb();
 const base={visibleInSearch:true,lookingNow:true,autoMatchAlertsEnabled:true,region:'EU',platform:'PS5',
  crossplayEnabled:true,preferredMaps:['The Blue Gate'],updatedAt:new Date(now-10000)};
 d[`arc_match_rider_profiles/${ids[0]}`]={...base,uid:ids[0]};
 d[`arc_match_rider_profiles/${ids[1]}`]={...base,uid:ids[1]};
 const n={pass13Discovery:true,type:'matchmaking',targetUid:ids[0],actorUid:ids[1]};
 assert.equal(await canDeliver(makeDb(d),admin,n,now),true);
 d[`arc_match_rider_profiles/${ids[1]}`].updatedAt=new Date(now-7*3600000);
 assert.equal(await canDeliver(makeDb(d),admin,n,now),false);
});
