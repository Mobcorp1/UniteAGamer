'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  COMMERCIAL_ECONOMY,
  creatorAcquisitionDiscountPercent,
  creatorCommissionEligible,
  ownerCampaignPolicy,
  monthKey,
  giftRecipientEligible,
} = require('../uag_commercial_economy');

test('locked prices and allowances match beta commercial model', () => {
  assert.equal(COMMERCIAL_ECONOMY.prices.essentialMonthlyPence, 499);
  assert.equal(COMMERCIAL_ECONOMY.prices.essentialAnnualPence, 4999);
  assert.equal(COMMERCIAL_ECONOMY.prices.premiumMonthlyPence, 899);
  assert.equal(COMMERCIAL_ECONOMY.prices.premiumAnnualPence, 8999);
  assert.equal(COMMERCIAL_ECONOMY.allowances.freeMonthlyTrades, 5);
  assert.equal(COMMERCIAL_ECONOMY.allowances.freeMonthlyMatchRaiderActions, 5);
  assert.equal(COMMERCIAL_ECONOMY.allowances.essentialMonthlyTrades, 30);
  assert.equal(COMMERCIAL_ECONOMY.allowances.essentialMonthlyMatchRaiderActions, 30);
});

test('Raider Mark economy is capped well below paid usage', () => {
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.marksPerCompletedAd, 1);
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.marksPerBonusAction, 5);
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.walletCap, 10);
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.maxRewardedAdsPerDay, 3);
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.maxRewardedAdsPerMonth, 20);
  assert.equal(COMMERCIAL_ECONOMY.raiderMarks.maxBonusRedemptionsPerMonth, 4);
});

test('creator discounts default to 20 and 50 percent kills commission', () => {
  assert.equal(creatorAcquisitionDiscountPercent(undefined), 20);
  assert.equal(creatorAcquisitionDiscountPercent(25), 25);
  assert.equal(creatorAcquisitionDiscountPercent(50), 50);
  assert.equal(creatorCommissionEligible(20), true);
  assert.equal(creatorCommissionEligible(25), true);
  assert.equal(creatorCommissionEligible(50), false);
});

test('owner campaigns are non-stackable, capped and monthly-plan only', () => {
  const now = Date.UTC(2026, 8, 29);
  const policy = ownerCampaignPolicy({
    code: 'MIKE25',
    preset: 'owner_25',
    status: 'active',
    redemptions: 3,
    maxRedemptions: 50,
  }, 'premium_monthly', now);
  assert.ok(policy);
  assert.equal(policy.discountPercent, 25);
  assert.equal(policy.commissionEligible, false);
  assert.equal(policy.stackable, false);
  assert.equal(
    ownerCampaignPolicy({
      code: 'MIKE25',
      preset: 'owner_25',
      status: 'active',
    }, 'premium_yearly', now),
    null,
  );
  assert.equal(
    ownerCampaignPolicy({
      code: 'MIKE25',
      preset: 'owner_25',
      status: 'active',
      redemptions: 49,
      reservedRedemptions: 1,
      maxRedemptions: 50,
    }, 'premium_monthly', now),
    null,
  );
});

test('gift rules block self-gifting and paid recipients', () => {
  assert.equal(giftRecipientEligible({
    purchaserUid: 'a',
    recipientUid: 'a',
    recipientHasActivePaidAccess: false,
  }), false);
  assert.equal(giftRecipientEligible({
    purchaserUid: 'a',
    recipientUid: 'b',
    recipientHasActivePaidAccess: true,
  }), false);
  assert.equal(giftRecipientEligible({
    purchaserUid: 'a',
    recipientUid: 'b',
    recipientHasActivePaidAccess: false,
  }), true);
});

test('month key is UTC stable', () => {
  assert.equal(monthKey(new Date('2026-09-29T23:30:00Z')), '2026-09');
});
