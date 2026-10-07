'use strict';

const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

const source = fs.readFileSync(path.join(__dirname, '..', 'index.js'), 'utf8');

test('completed trades award reputation and bounded Raid Intelligence credit exactly once', () => {
  assert.match(source, /TRADE_COMPLETION_REPUTATION_POINTS\s*=\s*25/);
  assert.match(source, /TRADE_COMPLETION_INTEL_REWARD_MONTHLY_CAP\s*=\s*4/);
  assert.match(source, /uag_trade_completion_rewards/);
  assert.match(source, /tradeCompletionIntelRewards/);
  assert.match(source, /premiumIntelUnlocks/);
  assert.match(source, /rewardCompletedTradingSession\(\{ sessionId, beforeData, afterData \}\)/);
  assert.match(source, /if \(rewardSnap\.exists\) return;/);
});
