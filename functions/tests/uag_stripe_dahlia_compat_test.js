'use strict';

const assert = require('assert');
const fs = require('fs');
const {
  subscriptionCurrentPeriodEndSeconds,
} = require('../stripe_subscription_compat');

assert.strictEqual(
  subscriptionCurrentPeriodEndSeconds({
    current_period_end: 1800000000,
    items: { data: [{ current_period_end: 1900000000 }] },
  }),
  1800000000,
  'Acacia payload should prefer the legacy top-level period when present.',
);

assert.strictEqual(
  subscriptionCurrentPeriodEndSeconds({
    items: { data: [{ current_period_end: 1900000000 }] },
  }),
  1900000000,
  'Dahlia payload should use the subscription item period.',
);

assert.strictEqual(
  subscriptionCurrentPeriodEndSeconds({
    items: {
      data: [
        { current_period_end: 1900000000 },
        { current_period_end: 1950000000 },
      ],
    },
  }),
  1950000000,
  'Multiple item periods should use the latest end time.',
);

assert.strictEqual(
  subscriptionCurrentPeriodEndSeconds({
    current_period_end: 'bad',
    items: { data: [{ current_period_end: '2000000000' }] },
  }),
  2000000000,
  'Invalid legacy data should fall back to the item period.',
);

assert.strictEqual(
  subscriptionCurrentPeriodEndSeconds({ items: { data: [] } }),
  0,
  'Missing period data must return 0 rather than NaN.',
);

const source = fs.readFileSync('functions/index.js', 'utf8');
assert(
  source.includes("require('./stripe_subscription_compat')"),
  'functions/index.js must load the Stripe compatibility helper.',
);
assert(
  source.includes('subscriptionCurrentPeriodEndTimestamp(subscription)'),
  'functions/index.js must convert compatible period values to Firestore timestamps.',
);
assert(
  !source.includes('subscription.current_period_end'),
  'Production webhook handling must not directly depend on the removed top-level field.',
);

console.log('UAG Stripe Dahlia compatibility: PASS');
