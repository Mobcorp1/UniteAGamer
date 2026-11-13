'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const { COMMERCIAL_ECONOMY } = require('../uag_commercial_economy');
const {
  FREE_REFERRALS_PER_REWARD,
  PAID_REFERRALS_PER_REWARD,
  VALID_ACTIONS,
  earnedTokens,
  usageMonthKey,
} = require('../uag_referral_action_rewards');
const {
  VALID_COMPLETION_ACTIONS,
  MONTHLY_OPERATION_REWARDS,
} = require('../uag_operation_action_rewards');

test('Hub Credits and monthly plan allowances match the locked product contract', () => {
  assert.deepEqual(COMMERCIAL_ECONOMY.allowances, {
    freeMonthlyTrades: 5,
    freeMonthlyMatchRaiderActions: 5,
    freeMonthlyRaidIntelligenceUnlocks: 5,
    freeMonthlyRaidPlannerRuns: 5,
    essentialMonthlyTrades: 30,
    essentialMonthlyMatchRaiderActions: 30,
    essentialMonthlyRaidIntelligenceUnlocks: 30,
    essentialMonthlyRaidPlannerRuns: 30,
  });
  assert.deepEqual(COMMERCIAL_ECONOMY.hubCredits, {
    marksPerCompletedAd: 1,
    marksPerBonusAction: 5,
    walletCap: 10,
    maxRewardedAdsPerDay: 3,
    maxRewardedAdsPerMonth: 20,
    maxBonusRedemptionsPerMonth: 4,
    minimumIntervalMinutes: 20,
  });
});

test('monthly referral gameplay rewards stack at 10 free or 5 paid referrals', () => {
  assert.equal(FREE_REFERRALS_PER_REWARD, 10);
  assert.equal(PAID_REFERRALS_PER_REWARD, 5);
  assert.equal(earnedTokens(9, 4), 0);
  assert.equal(earnedTokens(10, 0), 1);
  assert.equal(earnedTokens(0, 5), 1);
  assert.equal(earnedTokens(20, 10), 4);
  assert.deepEqual(VALID_ACTIONS, ['trades', 'raidCompanionPresets']);
  assert.equal(usageMonthKey(Date.UTC(2026, 9, 4)), '2026-M10');
});

test('monthly Operations use the locked four challenge targets and universal completion lanes', () => {
  assert.deepEqual(MONTHLY_OPERATION_REWARDS, {
    monthly_trader_bronze: {
      action: 'trades',
      target: 5,
      label: '+1 Trade Action',
    },
    monthly_match_raider: {
      action: 'matchmakingSearches',
      target: 3,
      label: '+1 Match Raider Search',
    },
    monthly_intel_network: {
      action: 'premiumIntelUnlocks',
      target: 5,
      label: '+1 Raid Intelligence Unlock',
    },
    monthly_raid_runner: {
      action: 'raidCompanionPresets',
      target: 3,
      label: '+1 Raid Planner Run',
    },
  });
  assert.deepEqual(VALID_COMPLETION_ACTIONS, [
    'trades',
    'matchmakingSearches',
    'premiumIntelUnlocks',
    'raidCompanionPresets',
  ]);
});
