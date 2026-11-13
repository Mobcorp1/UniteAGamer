'use strict';

function positiveUnixSeconds(value) {
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds <= 0) return 0;
  return Math.floor(seconds);
}

function subscriptionCurrentPeriodEndSeconds(subscription) {
  const legacy = positiveUnixSeconds(subscription?.current_period_end);
  if (legacy) return legacy;

  const items = Array.isArray(subscription?.items?.data)
    ? subscription.items.data
    : [];

  let latest = 0;
  for (const item of items) {
    const itemPeriodEnd = positiveUnixSeconds(item?.current_period_end);
    if (itemPeriodEnd > latest) latest = itemPeriodEnd;
  }

  return latest;
}

module.exports = {
  subscriptionCurrentPeriodEndSeconds,
};
