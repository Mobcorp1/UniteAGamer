'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { tokenDigest, publicInviteUrl, safeAlias, inviteFromUri, isValidInvite } = require('../uag_trade_invite_gateway');
const { rewardTier, evaluateVerifiedConversions } = require('../uag_trade_referral_incentives');
test('opaque URL never embeds Firebase UID and cannot be guessed from digest', () => {
  const token = 'Abc123_-'.repeat(6);
  assert.equal(tokenDigest(token).length, 64);
  assert.ok(!tokenDigest(token).includes(token));
  assert.equal(inviteFromUri('https://unite-a-gamer.web.app/t/' + token), token);
  assert.equal(inviteFromUri('https://evil.example/t/' + token), null);
  assert.equal(inviteFromUri('https://unite-a-gamer.web.app/?referrer=uid&refcode=X'), null);
});
test('safe Raider alias strips markup and control characters', () => {
  assert.equal(safeAlias(' <x>Raider\n '), 'xRaider');
});
test('revoked and expired invitations are rejected', () => {
  assert.ok(!isValidInvite({ active: false, expiresAt: { toMillis: () => 200 } }, 100));
  assert.ok(!isValidInvite({ active: true, expiresAt: { toMillis: () => 100 } }, 100));
  assert.ok(isValidInvite({ active: true, expiresAt: { toMillis: () => 200 } }, 100));
});
test('paid conversions deduplicate people and exclude refunds', () => {
  const row = { referralSource: 'uag_trade_invite', type: 'invoice_paid', referralOwnerUid: 'A', uid: 'B', eligibleNetAmountPence: 600 };
  assert.deepEqual(evaluateVerifiedConversions([row, row, { ...row, uid: 'C', reversalType: 'refund' }]), { paidPeople: 1, netPence: 600 });
  assert.equal(rewardTier(3, 1200), 'essential');
  assert.equal(rewardTier(6, 3000), 'premium');
  assert.equal(rewardTier(3, 1100), null);
});

test('new personalised invitation URLs use the canonical uniteagamer.com domain', () => {
  const token = 'Abc123_-'.repeat(6);
  assert.equal(publicInviteUrl(token), `https://uniteagamer.com/t/${token}`);
  assert.equal(inviteFromUri(publicInviteUrl(token)), token);
  assert.throws(() => publicInviteUrl('not-a-valid-token'));
});
