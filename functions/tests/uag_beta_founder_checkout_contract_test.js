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
  "pricePence: 2999",
  "premium_pass_day",
  "premium_pass_week",
  "uag_commercial_recognition",
  "loadCommercialRecognition(uid)",
  "assertPlanEligibility(plan, userData, recognitionData)",
  "mode: plan.kind === 'pass' ? 'payment' : 'subscription'",
  "writePremiumPassEntitlement",
  "founderRateForfeited: true",
  "subscription.cancellation_details?.reason === 'cancellation_requested'",
  "safeCheckoutReturnUrl",
  "setCheckoutCors",
];

for (const token of requiredSourceTokens) {
  assert(source.includes(token), `Missing beta/founder checkout token: ${token}`);
}

assert(
  rules.includes('match /uag_commercial_recognition/{userId}'),
  'Secure commercial recognition collection rules are missing.',
);
assert(
  rules.includes('allow create, update, delete: if isAdminOrDev();'),
  'Commercial recognition writes must stay admin/dev only.',
);
assert(
  rules.includes('ownerUserCommercialFieldsUnchanged'),
  'User commercial fields must be protected from owner-side entitlement escalation.',
);

console.log('UAG beta/founder checkout contract: PASS');
