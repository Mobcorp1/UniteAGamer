const fs = require('fs');
const assert = require('assert');

const source = fs.readFileSync('functions/index.js', 'utf8');

for (const token of [
  "source: 'uag_creator_programme'",
  "approvedCreatorProgrammeApplication",
  "planId === 'premium_monthly'",
  "amount_off: 200",
  "currency: 'gbp'",
  "approved_creator_premium_at_essential_price",
  "subscriberDiscountPercent",
  "subscriberDiscountDuration",
  "creatorBenefitApplied",
]) {
  assert(source.includes(token), `Missing product closure token: ${token}`);
}

assert(
  !source.includes("duration: 'forever',\\n        name: `UAG ${plan.creatorDiscountPercent}% Creator Discount"),
  'Legacy automatic permanent Creator-code follower discount is still active.',
);

assert(
  !source.includes("collection('referral_codes').doc(code).get()"),
  'Legacy referral_codes collection can still create Creator cash attribution.',
);

console.log('UAG Creator + Referral product closure contract: PASS');
