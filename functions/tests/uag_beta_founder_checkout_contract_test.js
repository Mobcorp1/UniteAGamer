const fs = require('fs');
const assert = require('assert');

const source = fs.readFileSync('functions/index.js', 'utf8');
const rules = fs.readFileSync('firestore.rules', 'utf8');

const requiredSourceTokens = [
  "beta_premium_monthly",
  "pricePence: 699",
  "beta_premium_yearly",
  "pricePence: 4999",
  "founding_raider_premium_yearly",
  "pricePence: COMMERCIAL_ECONOMY.prices.founderPremiumAnnualPence",
  "premium_pass_day",
  "premium_pass_week",
  "uag_commercial_recognition",
  "loadCommercialRecognition(uid)",
  "assertPlanEligibility(plan, userData, recognitionData)",
  "const oneTimePurchase = plan.kind === 'pass' || plan.kind === 'gift';",
  "mode: oneTimePurchase ? 'payment' : 'subscription'",
  "writePremiumPassEntitlement",
  "founderRateForfeited: true",
  "subscription.cancellation_details?.reason === 'cancellation_requested'",
  "safeCheckoutReturnUrl",
  "setCheckoutCors",
  "exports.setUagFoundingRaiderStatus = onRequest",
  "COMMERCIAL_ECONOMY.founder.membershipCap",
  "uag_commercial_counters",
];

for (const token of requiredSourceTokens) {
  assert(source.includes(token), `Missing beta/founder checkout token: ${token}`);
}

assert(
  rules.includes('match /uag_commercial_recognition/{userId}'),
  'Secure commercial recognition collection rules are missing.',
);
assert(
  rules.includes("request.resource.data.get('foundingRaider', false) =="),
  'Founder authority must not be writable directly from the admin client.',
);
assert(
  rules.includes('match /uag_commercial_counters/{counterId}'),
  'Server-owned Founder cohort counter rules are missing.',
);
assert(
  rules.includes('ownerUserCommercialFieldsUnchanged'),
  'User commercial fields must be protected from owner-side entitlement escalation.',
);

console.log('UAG beta/founder checkout contract: PASS');
