const fs = require('fs');
const assert = require('assert');

const source = fs.readFileSync('functions/index.js', 'utf8');

const required = [
  "uag_creator_campaign_code_requests",
  "eligibleNetAmountPence",
  "creatorCommissionRatePercent",
  "stripePaymentIntentId",
  "CREATOR_CANCELLATION_GRACE_DAYS = 30",
  "COMMUNITY_REFERRAL_VALIDATION_DAYS = 30",
  "uag_creator_referred_subscriptions",
  "recomputeCreatorCommercialAggregate",
  "resolveInvoiceIdForCharge",
  "queueCommunityReferralValidation",
  "uag_community_referral_validation_queue",
  "expireCreatorCancellationGraceDaily",
  "validateCommunityReferralsDaily",
  "server_retention_policy",
  "community_referral_${referrerUid}_1",
  "community_referral_${referrerUid}_3",
  "lifecycleStatus: 'pendingValidation'",
  "invoice.total_excluding_tax",
  "invoice.total_taxes",
];

for (const token of required) {
  assert(source.includes(token), `Missing lifecycle contract token: ${token}`);
}

assert(
  !source.includes(
    ".where('lifecycleStatus', '==', 'pendingValidation')\\n" +
    "    .where('qualificationDate', '<=', now)"
  ),
  'Old composite-index-dependent commission release query still present.',
);

console.log('UAG commercial lifecycle closure contract: PASS');
