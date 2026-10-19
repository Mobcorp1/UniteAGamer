'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { watchFitsListing, riderFits } = require('../uag_pass13_auto_matches');
const listing = { ownerUid: 'seller', active: true, expiresAt: {toMillis:()=>Date.now()+60000}, offeredBlueprintNames: ['Anvil'] };
const watch = { ownerUid:'buyer', active:true, notificationsEnabled:true, notificationPreference:'immediate', type:'blueprint', blueprintId:'anvil' };
test('watch requires an active authentic offered listing',()=>{
 assert.equal(watchFitsListing(watch,listing),true);
 assert.equal(watchFitsListing(watch,{...listing,active:false}),false);
 assert.equal(watchFitsListing(watch,{...listing,expiresAt:{toMillis:()=>1}}),false);
 assert.equal(watchFitsListing({...watch,blueprintId:'rascal'},listing),false);
 assert.equal(watchFitsListing({...watch,ownerUid:'seller'},listing),false);
});
test('muted, paused and non-blueprint watches never match',()=>{
 assert.equal(watchFitsListing({...watch,active:false},listing),false);
 assert.equal(watchFitsListing({...watch,notificationPreference:'muted'},listing),false);
 assert.equal(watchFitsListing({...watch,type:'rider'},listing),false);
});
const left={uid:'a',visibleInSearch:true,lookingNow:true,autoMatchAlertsEnabled:true,region:'EU', platform:'PS5',crossplayEnabled:true,preferredEvents:['ARC Frigate']};
const right={...left,uid:'b',platform:'PC'};
test('matching requires mutual opt-in, an activity, visibility, region and crossplay',()=>{
 assert.equal(riderFits(left,right),true);
 assert.equal(riderFits(left,{...right,autoMatchAlertsEnabled:false}),false);
 assert.equal(riderFits(left,{...right,lookingNow:false}),false);
 assert.equal(riderFits(left,{...right,preferredEvents:['Redirection']}),false);
 assert.equal(riderFits(left,{...right,region:'NA'}),false);
 assert.equal(riderFits({...left,crossplayEnabled:false},right),false);
 assert.equal(riderFits(left,{...right,blockedMatchRiderUids:['a']}),false);
});
