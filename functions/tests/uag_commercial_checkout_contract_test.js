'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(
  path.join(__dirname, '..', 'index.js'),
  'utf8',
);

test('checkout owns the locked subscription and gift prices', () => {
  assert.match(source, /essentialMonthlyPence/);
  assert.match(source, /essentialAnnualPence/);
  assert.match(source, /premiumMonthlyPence/);
  assert.match(source, /premiumAnnualPence/);
  assert.match(source, /founderPremiumAnnualPence/);
  assert.match(source, /gift_premium_month/);
  assert.match(source, /premiumGiftMonthPence/);
});

test('explicit promo codes are server validated and non-stackable', () => {
  assert.match(source, /resolveReferral\(effectiveReferralCode/);
  assert.match(
    source,
    /That promo, creator or referral code is not valid for this purchase\./,
  );
  assert.match(source, /commissionEligible/);
  assert.match(source, /nextRenewalFree/);
});

test('legacy and canonical referral registries remain compatible', () => {
  assert.match(source, /uag_community_referral_codes/);
  assert.match(source, /referral_codes/);
  assert.match(source, /ownerUid !== uid/);
});

test('gift purchase and redemption remain server authoritative', () => {
  assert.match(source, /async function issuePremiumGift/);
  assert.match(source, /exports\.redeemUagGift = onRequest/);
  assert.match(source, /You cannot redeem a Premium gift that you bought yourself\./);
  assert.match(source, /uag_gift_recipient_history/);
  assert.match(source, /reservedPurchases/);
  assert.match(source, /commercialReservationId/);
});

test('commercial checkout reservations close cap races', () => {
  assert.match(source, /reserveCommercialCheckout/);
  assert.match(source, /releaseCommercialCheckoutReservation/);
  assert.match(source, /reservedRedemptions/);
  assert.match(source, /checkout\.session\.expired/);
  assert.match(source, /uag_commercial_checkout_reservations/);
  assert.match(
    source,
    /An owner promotion checkout is already open for this account\./,
  );
});

test('creator commission ladder matches the canonical Dart policy', () => {
  assert.match(source, /if \(value >= 100\) return 20;/);
  assert.match(source, /if \(value >= 60\) return 17\.5;/);
  assert.match(source, /if \(value >= 40\) return 15;/);
  assert.match(source, /if \(value >= 25\) return 12\.5;/);
  assert.match(source, /if \(value >= 15\) return 10;/);
  assert.match(source, /if \(value >= 8\) return 7\.5;/);
  assert.match(source, /if \(value >= 1\) return 5;/);
});
