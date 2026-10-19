'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname,'../..');
const read = (p) => fs.readFileSync(path.join(root,p),'utf8');

test('trade trigger listens to the real TradingRepository collection', () => {
  const functions = read('functions/index.js');
  const repository = read('lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart');
  assert.match(repository, /\.collection\('trading_listings'\)/);
  assert.match(functions, /'trading_listings\/\{listingId\}', pass13AutoMatches\.onListing/);
  assert.match(functions, /'arc_blueprint_watches\/\{watchId\}', pass13AutoMatches\.onWatch/);
  assert.match(functions, /'arc_match_rider_profiles\/\{profileUid\}', pass13AutoMatches\.onRider/);
});
test('push delivery respects CURRENT user notification preference and absolute HTTPS click link', () => {
  const code = read('functions/index.js');
  assert.match(code,/notification_preferences'\)\.doc\('current'\)/);
  assert.match(code,/if \(currentPreference\.data\(\)\?\.\[preferenceKeyForType\(data\.type\)\] === false\) return/);
  assert.match(code,/https:\/\/uniteagamer\.com/);
  assert.match(code,/if \(!devicesSnap\.empty\) return targets/);
});
test('notification taps resolve current listings, not just generic search', () => {
  const code = read('lib/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart');
  assert.match(code,/notification\.type == TradingNotificationType\.blueprintWatchMatch/);
  assert.match(code,/getListingById\(notification\.listingId\)/);
});
test('manual search is still present behind the launch flag', () => {
  const match = read('lib/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart');
  const market = read('lib/features/trading_hub/arc_raiders/screens/trading_listings_screen.dart');
  assert.match(match,/UAG_SHOW_MANUAL_SEARCH/);
  assert.match(match,/_buildMatchesFeed\(profile\)/);
  assert.match(market,/UAG_SHOW_MANUAL_SEARCH/);
  assert.match(market,/TradingBlueprintWatchesScreen/);
});
test('sensitive activation control denies client writes',()=>{
  const rules = read('firestore.rules');
  assert.match(rules, /match \/uag_release_controls\/\{controlId\}/);
  assert.match(rules, /allow write: if false/);
});
