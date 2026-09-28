'use strict';

const COMMERCIAL_ECONOMY = Object.freeze({
  prices: Object.freeze({
    essentialMonthlyPence: 499,
    essentialAnnualPence: 4999,
    premiumMonthlyPence: 899,
    premiumAnnualPence: 8999,
    founderPremiumAnnualPence: 4499,
    premiumGiftMonthPence: 699,
  }),
  allowances: Object.freeze({
    freeMonthlyTrades: 5,
    freeMonthlyMatchRaiderActions: 5,
    essentialMonthlyTrades: 30,
    essentialMonthlyMatchRaiderActions: 30,
  }),
  discounts: Object.freeze({
    communityReferralPercent: 10,
    creatorStandardPercent: 20,
    creatorSelectedPercent: 25,
    ownerMaximumPercent: 50,
    founderAnnualPercent: 50,
  }),
  founder: Object.freeze({
    membershipCap: 100,
  }),
  gifts: Object.freeze({
    durationDays: 30,
    claimWindowDays: 30,
    recipientCooldownDays: 365,
    senderMonthlyCap: 5,
  }),
  raiderMarks: Object.freeze({
    marksPerCompletedAd: 1,
    marksPerBonusAction: 5,
    walletCap: 10,
    maxRewardedAdsPerDay: 3,
    maxRewardedAdsPerMonth: 20,
    maxBonusRedemptionsPerMonth: 4,
    minimumIntervalMinutes: 20,
  }),
  commissions: Object.freeze({
    validationDays: 30,
    payoutThresholdPence: 2500,
  }),
});

const OWNER_CAMPAIGN_PRESETS = Object.freeze({
  owner_20: Object.freeze({
    discountPercent: 20,
    defaultRedemptionCap: 100,
    commissionEligible: false,
    nextRenewalFree: false,
    allowedPlanIds: ['essential_monthly', 'premium_monthly'],
  }),
  owner_25: Object.freeze({
    discountPercent: 25,
    defaultRedemptionCap: 50,
    commissionEligible: false,
    nextRenewalFree: false,
    allowedPlanIds: ['essential_monthly', 'premium_monthly'],
  }),
  owner_50: Object.freeze({
    discountPercent: 50,
    defaultRedemptionCap: 25,
    commissionEligible: false,
    nextRenewalFree: false,
    allowedPlanIds: ['essential_monthly', 'premium_monthly'],
  }),
  christmas_next_renewal_free: Object.freeze({
    discountPercent: 0,
    defaultRedemptionCap: 250,
    commissionEligible: false,
    nextRenewalFree: true,
    allowedPlanIds: ['essential_monthly', 'premium_monthly'],
  }),
});

function normalizeCode(value) {
  return String(value || '')
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .slice(0, 28);
}

function creatorAcquisitionDiscountPercent(value) {
  const requested = Number(value);
  if (requested === 25) return 25;
  if (requested === 50) return 50;
  if (requested === 20) return 20;
  return COMMERCIAL_ECONOMY.discounts.creatorStandardPercent;
}

function creatorCommissionEligible(discountPercent) {
  const value = Number(discountPercent || 0);
  return value > 0 && value <= COMMERCIAL_ECONOMY.discounts.creatorSelectedPercent;
}

function ownerCampaignPreset(value) {
  const key = String(value || '').trim();
  return OWNER_CAMPAIGN_PRESETS[key] || null;
}

function timestampMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'number') return value;
  const parsed = Date.parse(String(value));
  return Number.isFinite(parsed) ? parsed : 0;
}

function ownerCampaignPolicy(data, planId, nowMillis = Date.now()) {
  if (!data || String(data.status || '').toLowerCase() !== 'active') return null;
  const code = normalizeCode(data.code || data.id);
  if (!code) return null;

  const preset = ownerCampaignPreset(data.preset);
  if (!preset) return null;

  const startsAt = timestampMillis(data.startsAt);
  const endsAt = timestampMillis(data.endsAt);
  if (startsAt && startsAt > nowMillis) return null;
  if (endsAt && endsAt <= nowMillis) return null;

  const allowedPlanIds = Array.isArray(data.allowedPlanIds) && data.allowedPlanIds.length
    ? data.allowedPlanIds.map(String)
    : preset.allowedPlanIds;
  if (!allowedPlanIds.includes(planId)) return null;

  const maxRedemptions = Math.max(
    1,
    Number(data.maxRedemptions || preset.defaultRedemptionCap) || preset.defaultRedemptionCap,
  );
  const redemptions = Math.max(0, Number(data.redemptions || 0) || 0);
  if (redemptions >= maxRedemptions) return null;

  return {
    code,
    source: 'uag_owner_campaign',
    ownerUid: '',
    discountPercent: preset.discountPercent,
    duration: 'once',
    commissionEligible: false,
    nextRenewalFree: preset.nextRenewalFree,
    newCustomersOnly: data.newCustomersOnly !== false,
    stackable: false,
    maxRedemptions,
    redemptions,
    preset: String(data.preset || ''),
  };
}

function monthKey(date = new Date()) {
  const value = date instanceof Date ? date : new Date(date);
  const year = value.getUTCFullYear();
  const month = String(value.getUTCMonth() + 1).padStart(2, '0');
  return `${year}-${month}`;
}

function giftClaimExpiryMillis(paidAtMillis) {
  return Number(paidAtMillis) +
    COMMERCIAL_ECONOMY.gifts.claimWindowDays * 24 * 60 * 60 * 1000;
}

function giftEntitlementExpiryMillis(startedAtMillis) {
  return Number(startedAtMillis) +
    COMMERCIAL_ECONOMY.gifts.durationDays * 24 * 60 * 60 * 1000;
}

function giftRecipientEligible({
  purchaserUid,
  recipientUid,
  recipientHasActivePaidAccess,
  lastRedeemedAtMillis = 0,
  nowMillis = Date.now(),
}) {
  if (!purchaserUid || !recipientUid || purchaserUid === recipientUid) return false;
  if (recipientHasActivePaidAccess) return false;
  if (!lastRedeemedAtMillis) return true;
  const cooldownMillis =
    COMMERCIAL_ECONOMY.gifts.recipientCooldownDays * 24 * 60 * 60 * 1000;
  return nowMillis - Number(lastRedeemedAtMillis) >= cooldownMillis;
}

module.exports = {
  COMMERCIAL_ECONOMY,
  OWNER_CAMPAIGN_PRESETS,
  normalizeCode,
  creatorAcquisitionDiscountPercent,
  creatorCommissionEligible,
  ownerCampaignPreset,
  ownerCampaignPolicy,
  timestampMillis,
  monthKey,
  giftClaimExpiryMillis,
  giftEntitlementExpiryMillis,
  giftRecipientEligible,
};
