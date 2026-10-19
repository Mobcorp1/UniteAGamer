'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../..');
const read=(file)=>fs.readFileSync(path.join(root,file),'utf8');
test('qa module is checked immediately before FCM delivery',()=>{
 const index=read('functions/index.js');
 assert.match(index,/const pass13CQA = require\('\.\/uag_pass13c_qa_guard'\)/);
 assert.match(index,/data\.pass13Discovery === true && !\(await pass13CQA\.canDeliver\(db, admin, data\)\)/);
 assert.match(index,/trading_listings\/\{listingId\}/);
 assert.match(index,/exports\.uagPass13WatchBlueprintWatches/);
 assert.match(index,/exports\.uagPass13WatchMatchRider/);
 assert.match(index,/exports\.sendTradingNotificationPush/);
});
test('autodiscovery only queues messages for QA pairs and is not an auto trade',()=>{
 const matcher=read('functions/uag_pass13_auto_matches.js');
 assert.match(matcher,/pass13Discovery: true/);
 assert.match(matcher,/qa\.qaPairAllowed/);
 assert.match(matcher,/qa\.qaMemberAllowed/);
 assert.match(matcher,/\bqaPair\(buyerUid, sellerUid/);
 assert.match(matcher,/\bqaPair\(snap\.id, candidate\.id/);
 assert.doesNotMatch(matcher,/acceptTrade\(/);
});
test('Firestore release controls remain server-owned and client cannot spoof matching',()=>{
 const rules=read('firestore.rules');
 assert.match(rules,/match \/uag_release_controls\/\{controlId\}/);
 assert.match(rules,/allow write: if false/);
 assert.match(rules,/!\(request\.resource\.data\.type in \['watch_match', 'matchmaking'\]\)/);
});
test('existing search and invite UI stays in repo',()=>{
 const match=read('lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart');
 const trades=read('lib/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart');
 assert.match(match,/UAG_SHOW_MANUAL_SEARCH/);
 assert.match(match,/_buildMatchesFeed\(profile\)/);
 assert.match(trades,/UAG_SHOW_MANUAL_SEARCH/);
});
