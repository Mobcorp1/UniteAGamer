const fs = require('fs');
const assert = require('assert');

const source = fs.readFileSync('functions/index.js', 'utf8');
const rules = fs.readFileSync('firestore.rules', 'utf8');

for (const token of [
  'pricePence: 6999',
  'pricePence: 8999',
  'pricePence: 349',
  "source: 'uag_community_referral'",
  'subscriberDiscountPercent: 10',
  'communityBaseCommissionRate',
  'premiumReferralBoost',
  'authoritativeCommunityCommissionRate',
  'syncCommunityPaidReferralSubscription',
  'uag_community_referral_paid_subscriptions',
  'uag_community_referral_commission_ledgers',
  "referralSource: referral?.source || ''",
  'const charityPence = 0',
]) {
  assert(source.includes(token), `Missing convergence token: ${token}`);
}

assert(
  !source.includes('The introductory 24-hour Premium pass has already been used'),
  '24-hour pass is still one-use-only.',
);
assert(
  !source.includes('The introductory 7-day Premium pass has already been used'),
  '7-day pass is still one-use-only.',
);
assert(
  !source.includes('charityProfitPercent: 10') &&
    !source.includes('charityProfitPercent: 20'),
  'Automatic per-plan charity deductions are still active.',
);
assert(
  rules.includes('match /uag_community_referral_paid_subscriptions/{subscriptionId}'),
  'Community paid-referral lifecycle rules are missing.',
);
assert(
  rules.includes('match /uag_community_referral_commission_ledgers/{referrerUid}'),
  'Community commission ledger rules are missing.',
);

console.log('UAG monetisation commercial convergence contract: PASS');
