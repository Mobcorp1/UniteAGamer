const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const Stripe = require('stripe');

admin.initializeApp();

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

const db = admin.firestore();

const PLAN_CONFIG = {
  essential_monthly: {
    tier: 'essential',
    billingPeriod: 'monthly',
    pricePence: 599,
    stripePriceEnv: 'STRIPE_PRICE_ESSENTIAL_MONTHLY',
    creatorDiscountPercent: 10,
    creatorCommissionPercent: 10,
    charityProfitPercent: 10,
    impactPotId: 'essential',
  },
  essential_yearly: {
    tier: 'essential',
    billingPeriod: 'yearly',
    pricePence: 4999,
    stripePriceEnv: 'STRIPE_PRICE_ESSENTIAL_YEARLY',
    creatorDiscountPercent: 10,
    creatorCommissionPercent: 10,
    charityProfitPercent: 10,
    impactPotId: 'essential',
  },
  premium_monthly: {
    tier: 'premium',
    billingPeriod: 'monthly',
    pricePence: 1099,
    stripePriceEnv: 'STRIPE_PRICE_PREMIUM_MONTHLY',
    creatorDiscountPercent: 20,
    creatorCommissionPercent: 20,
    charityProfitPercent: 20,
    impactPotId: 'premium',
  },
  premium_yearly: {
    tier: 'premium',
    billingPeriod: 'yearly',
    pricePence: 9499,
    stripePriceEnv: 'STRIPE_PRICE_PREMIUM_YEARLY',
    creatorDiscountPercent: 20,
    creatorCommissionPercent: 20,
    charityProfitPercent: 20,
    impactPotId: 'premium',
  },
};

function stripeClient() {
  return Stripe(stripeSecretKey.value(), { apiVersion: '2024-12-18.acacia' });
}

function estimateStripeFeePence(grossPence) {
  // Conservative UK card estimate. Bacs and international cards can differ.
  return Math.round(grossPence * 0.015) + 20;
}

function getPlan(planId) {
  const plan = PLAN_CONFIG[planId];
  if (!plan) throw new Error(`Unknown UAG plan: ${planId}`);
  return plan;
}

async function resolveReferral(referralCode) {
  const code = String(referralCode || '').trim().toUpperCase();
  if (!code) return null;
  const snap = await db.collection('referral_codes').doc(code).get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  if (data.active === false || !data.ownerUid) return null;
  return { code, ownerUid: data.ownerUid };
}

exports.createUagCheckoutSession = onRequest({ secrets: [stripeSecretKey] }, async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const authHeader = req.headers.authorization || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const { planId, referralCode, successUrl, cancelUrl } = req.body || {};
    const plan = getPlan(planId);
    const priceId = process.env[plan.stripePriceEnv];
    if (!priceId) throw new Error(`Missing Stripe price env: ${plan.stripePriceEnv}`);

    const userRef = db.collection('users').doc(uid);
    const userSnap = await userRef.get();
    const userData = userSnap.data() || {};
    let customerId = userData?.monetisation?.stripeCustomerId || userData.stripeCustomerId;
    const stripe = stripeClient();

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: decoded.email || undefined,
        metadata: { uid },
      });
      customerId = customer.id;
      await userRef.set({ monetisation: { stripeCustomerId: customerId, updatedAt: admin.firestore.FieldValue.serverTimestamp() } }, { merge: true });
    }

    const referral = await resolveReferral(referralCode);
    const discounts = [];
    if (referral && referral.ownerUid !== uid && plan.creatorDiscountPercent > 0) {
      const coupon = await stripe.coupons.create({
        percent_off: plan.creatorDiscountPercent,
        duration: 'forever',
        name: `UAG ${plan.creatorDiscountPercent}% Creator Discount ${referral.code}`,
        metadata: { referralCode: referral.code, ownerUid: referral.ownerUid, planId },
      });
      discounts.push({ coupon: coupon.id });
    }

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: uid,
      payment_method_types: ['card', 'bacs_debit'],
      discounts,
      metadata: {
        uid,
        planId,
        tier: plan.tier,
        billingPeriod: plan.billingPeriod,
        referralCode: referral?.code || '',
        referralOwnerUid: referral?.ownerUid || '',
      },
      subscription_data: {
        metadata: {
          uid,
          planId,
          tier: plan.tier,
          billingPeriod: plan.billingPeriod,
          referralCode: referral?.code || '',
          referralOwnerUid: referral?.ownerUid || '',
        },
      },
    });

    await db.collection('monetisation_checkout_sessions').doc(session.id).set({
      id: session.id,
      uid,
      planId,
      tier: plan.tier,
      billingPeriod: plan.billingPeriod,
      referralCode: referral?.code || null,
      referralOwnerUid: referral?.ownerUid || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: session.status || 'created',
    });

    res.status(200).json({ checkoutUrl: session.url, sessionId: session.id });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message || 'Checkout failed' });
  }
});

exports.createUagCustomerPortalSession = onRequest({ secrets: [stripeSecretKey] }, async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }
    const authHeader = req.headers.authorization || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;
    const userSnap = await db.collection('users').doc(uid).get();
    const userData = userSnap.data() || {};
    const customerId = userData?.monetisation?.stripeCustomerId || userData.stripeCustomerId;
    if (!customerId) throw new Error('No Stripe customer found for this account.');
    const stripe = stripeClient();
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: req.body?.returnUrl,
    });
    res.status(200).json({ portalUrl: session.url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message || 'Customer portal failed' });
  }
});

exports.uagStripeWebhook = onRequest({ secrets: [stripeSecretKey, stripeWebhookSecret] }, async (req, res) => {
  const stripe = stripeClient();
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, req.headers['stripe-signature'], stripeWebhookSecret.value());
  } catch (error) {
    console.error('Stripe webhook signature failed', error);
    res.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }

  try {
    if (event.type === 'checkout.session.completed') {
      await handleCheckoutCompleted(event.data.object);
    }
    if (event.type === 'customer.subscription.updated' || event.type === 'customer.subscription.created') {
      await handleSubscriptionUpdated(event.data.object);
    }
    if (event.type === 'customer.subscription.deleted') {
      await handleSubscriptionDeleted(event.data.object);
    }
    if (event.type === 'invoice.paid') {
      await handleInvoicePaid(event.data.object);
    }
    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook handling failed', error);
    res.status(500).send(error.message || 'Webhook handling failed');
  }
});

async function handleCheckoutCompleted(session) {
  const uid = session.metadata?.uid || session.client_reference_id;
  if (!uid) return;
  const plan = getPlan(session.metadata?.planId);
  await db.collection('users').doc(uid).set({
    monetisation: {
      tier: plan.tier,
      subscriptionStatus: 'active',
      billingPeriod: plan.billingPeriod,
      stripeCustomerId: session.customer || null,
      stripeSubscriptionId: session.subscription || null,
      referralCodeUsed: session.metadata?.referralCode || null,
      referredByUid: session.metadata?.referralOwnerUid || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: plan.tier,
    subscriptionStatus: 'active',
  }, { merge: true });
}

async function handleSubscriptionUpdated(subscription) {
  const uid = subscription.metadata?.uid;
  if (!uid) return;
  const plan = getPlan(subscription.metadata?.planId);
  await db.collection('users').doc(uid).set({
    monetisation: {
      tier: subscription.status === 'active' || subscription.status === 'trialing' ? plan.tier : 'free',
      subscriptionStatus: subscription.status,
      billingPeriod: plan.billingPeriod,
      stripeSubscriptionId: subscription.id,
      currentPeriodEnd: admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: subscription.status === 'active' || subscription.status === 'trialing' ? plan.tier : 'free',
    subscriptionStatus: subscription.status,
  }, { merge: true });
}

async function handleSubscriptionDeleted(subscription) {
  const uid = subscription.metadata?.uid;
  if (!uid) return;
  await db.collection('users').doc(uid).set({
    monetisation: {
      tier: 'free',
      subscriptionStatus: 'cancelled',
      stripeSubscriptionId: subscription.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: 'free',
    subscriptionStatus: 'cancelled',
  }, { merge: true });
}

async function handleInvoicePaid(invoice) {
  const subscriptionId = invoice.subscription;
  if (!subscriptionId) return;
  const stripe = stripeClient();
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const uid = subscription.metadata?.uid;
  const planId = subscription.metadata?.planId;
  if (!uid || !planId) return;

  const plan = getPlan(planId);
  const grossPence = invoice.amount_paid || plan.pricePence;
  const stripeFeePence = estimateStripeFeePence(grossPence);
  const referralOwnerUid = subscription.metadata?.referralOwnerUid || '';
  const referralCode = subscription.metadata?.referralCode || '';
  const referralCommissionPence = referralOwnerUid ? Math.floor(grossPence * (plan.creatorCommissionPercent / 100)) : 0;
  const netBeforeCharity = Math.max(0, grossPence - stripeFeePence - referralCommissionPence);
  const charityPence = Math.floor(netBeforeCharity * (plan.charityProfitPercent / 100));
  const netPlatformProfitPence = Math.max(0, netBeforeCharity - charityPence);

  const eventRef = db.collection('monetisation_events').doc(invoice.id);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(eventRef);
    if (existing.exists) return;

    transaction.set(eventRef, {
      id: invoice.id,
      type: 'invoice_paid',
      uid,
      planId,
      tier: plan.tier,
      billingPeriod: plan.billingPeriod,
      grossPence,
      stripeFeePence,
      referralCommissionPence,
      charityPence,
      netPlatformProfitPence,
      referralOwnerUid: referralOwnerUid || null,
      referralCode: referralCode || null,
      stripeInvoiceId: invoice.id,
      stripeSubscriptionId: subscriptionId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (referralOwnerUid && referralCommissionPence > 0) {
      const walletRef = db.collection('referral_wallets').doc(referralOwnerUid);
      transaction.set(walletRef, {
        uid: referralOwnerUid,
        pendingPence: admin.firestore.FieldValue.increment(referralCommissionPence),
        totalEarnedPence: admin.firestore.FieldValue.increment(referralCommissionPence),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(walletRef.collection('ledger').doc(invoice.id), {
        id: invoice.id,
        type: 'commission_pending',
        amountPence: referralCommissionPence,
        referredUid: uid,
        planId,
        referralCode,
        releaseAfter: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (charityPence > 0) {
      const potRef = db.collection('impact_pots').doc(plan.impactPotId);
      transaction.set(potRef, {
        id: plan.impactPotId,
        label: plan.tier === 'essential' ? 'Essential Impact Pot' : 'Premium Impact Pot',
        sortOrder: plan.tier === 'essential' ? 10 : 20,
        monthlyPence: admin.firestore.FieldValue.increment(charityPence),
        allTimePence: admin.firestore.FieldValue.increment(charityPence),
        contributingUsers: admin.firestore.FieldValue.increment(1),
        lastAllocatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  });
}

function normalizeString(value) {
  return String(value || '').trim();
}

function isInvalidTokenCode(code) {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token'
  );
}

function permissionAllowsPush(status) {
  const normalized = normalizeString(status).toLowerCase();
  return normalized === 'authorized' || normalized === 'granted' || normalized === 'provisional';
}

function preferenceKeyForType(type) {
  switch (normalizeString(type)) {
    case 'open_beta':
      return 'openBetaUpdates';
    case 'trading':
    case 'offerReceived':
    case 'offerAccepted':
    case 'offerDeclined':
    case 'offerCancelled':
    case 'sessionCreated':
    case 'sessionUpdated':
    case 'sessionReady':
    case 'sessionOutcome':
      return 'trading';
    case 'matchmaking':
      return 'matchmaking';
    case 'favourite_rider':
      return 'favouriteRiders';
    case 'watch_match':
    case 'queue_release':
    case 'blueprintWatchMatch':
    case 'queuedListingReleased':
    case 'queuedListingBlocked':
      return 'watchesAndQueues';
    case 'operations':
    case 'reward':
      return 'operationsAndRewards';
    case 'community_event':
      return 'communityEvents';
    case 'reminder':
    case 'scheduledTradeReminder':
      return 'reminders';
    case 'post_session_feedback':
      return 'postSessionFeedback';
    case 'announcement':
    case 'maintenance':
    default:
      return 'announcements';
  }
}

function preferencesAllowType(preferences, type) {
  const key = preferenceKeyForType(type);
  if (!preferences || typeof preferences !== 'object') return true;
  if (preferences[key] === false) return false;
  return true;
}

function deliveryDataFromNotification(data, notificationId) {
  return {
    id: normalizeString(data.id || notificationId),
    notificationId: normalizeString(notificationId),
    type: normalizeString(data.type),
    listingId: normalizeString(data.listingId),
    offerId: normalizeString(data.offerId),
    sessionId: normalizeString(data.sessionId),
    route: normalizeString(data.route),
    deepLink: normalizeString(data.deepLink),
    entityId: normalizeString(data.entityId),
    audience: normalizeString(data.audience),
    priority: normalizeString(data.priority || 'normal'),
  };
}

function buildMessage({ data, tokens }) {
  const imageUrl = normalizeString(data.imageUrl);
  const notification = {
    title: normalizeString(data.title) || 'UAG Arc Raiders Hub',
    body: normalizeString(data.body) || 'Open the app for details.',
  };
  if (imageUrl) notification.imageUrl = imageUrl;

  return {
    notification,
    data: deliveryDataFromNotification(data, data.id),
    android: {
      priority: data.priority === 'critical' || data.priority === 'high' ? 'high' : 'normal',
      notification: {
        channelId: 'trading_alerts',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    webpush: {
      notification: {
        title: notification.title,
        body: notification.body,
        icon: '/icons/uag-hub-192.png',
        image: imageUrl || undefined,
        data: deliveryDataFromNotification(data, data.id),
      },
      fcmOptions: {
        link: normalizeString(data.deepLink || data.route || '/') || '/',
      },
    },
    tokens,
  };
}

async function loadUserPushTargets(uid, type) {
  const targets = [];
  const seen = new Set();
  const devicesSnap = await db
    .collection('users')
    .doc(uid)
    .collection('notification_devices')
    .where('enabled', '==', true)
    .get();

  devicesSnap.docs.forEach((doc) => {
    const device = doc.data() || {};
    const token = normalizeString(device.token);
    if (!token || seen.has(token)) return;
    if (device.tokenValid === false) return;
    if (!permissionAllowsPush(device.permissionStatus)) return;
    if (!preferencesAllowType(device.preferences, type)) return;
    seen.add(token);
    targets.push({ token, ref: doc.ref, legacy: false });
  });

  const legacySnap = await db
    .collection('users')
    .doc(uid)
    .collection('notification_tokens')
    .get();

  legacySnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    const token = normalizeString(data.token || doc.id);
    if (!token || seen.has(token) || data.enabled === false) return;
    seen.add(token);
    targets.push({ token, ref: doc.ref, legacy: true });
  });

  return targets;
}

async function sendToTargets({ notificationData, targets }) {
  const chunks = [];
  for (let i = 0; i < targets.length; i += 500) {
    chunks.push(targets.slice(i, i + 500));
  }

  const totals = {
    attempted: 0,
    successful: 0,
    failed: 0,
    invalidTokens: 0,
  };

  for (const chunk of chunks) {
    const tokens = chunk.map((target) => target.token);
    if (!tokens.length) continue;
    totals.attempted += tokens.length;
    const response = await admin.messaging().sendEachForMulticast(
      buildMessage({ data: notificationData, tokens })
    );
    totals.successful += response.successCount;
    totals.failed += response.failureCount;

    const batch = db.batch();
    response.responses.forEach((result, index) => {
      if (result.success) return;
      const code = result.error && result.error.code;
      if (!isInvalidTokenCode(code)) return;
      totals.invalidTokens += 1;
      const target = chunk[index];
      if (target.legacy) {
        batch.delete(target.ref);
      } else {
        batch.set(target.ref, {
          enabled: false,
          tokenValid: false,
          invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          invalidReason: code,
        }, { merge: true });
      }
    });
    await batch.commit();
  }

  return totals;
}

async function isAdminUser(uid) {
  if (!uid) return false;
  const userSnap = await db.collection('users').doc(uid).get();
  const data = userSnap.data() || {};
  return data.isAdmin === true || data.isDev === true;
}

function userMatchesAudience({ audience, userData }) {
  switch (audience) {
    case 'closed_beta_users':
      return userData.closedBetaParticipant === true || userData.betaParticipant === true;
    case 'open_beta_users':
      return userData.openBetaParticipant === true || userData.openBetaEligible === true;
    default:
      return true;
  }
}

async function loadBroadcastTargets(data) {
  const audience = normalizeString(data.audience || 'all_eligible');
  const targetUid = normalizeString(data.targetUid);
  const type = normalizeString(data.type);
  let query = db.collectionGroup('notification_devices')
    .where('enabled', '==', true)
    .where('tokenValid', '==', true)
    .limit(1000);

  if (audience === 'android') query = query.where('platform', '==', 'android');
  if (audience === 'web') query = query.where('platform', '==', 'web');
  if (audience === 'specific_user' && targetUid) {
    query = query.where('userId', '==', targetUid);
  }

  const snap = await query.get();
  const targets = [];
  const userIds = new Set();
  const userCache = new Map();
  const seenTokens = new Set();
  let skippedByPreference = 0;

  for (const doc of snap.docs) {
    const device = doc.data() || {};
    const uid = normalizeString(device.userId);
    const token = normalizeString(device.token);
    if (!uid || !token || seenTokens.has(token)) continue;
    if (!permissionAllowsPush(device.permissionStatus)) continue;
    if (!preferencesAllowType(device.preferences, type)) {
      skippedByPreference += 1;
      continue;
    }
    if (audience === 'specific_user' && uid !== targetUid) continue;

    if (audience === 'closed_beta_users' || audience === 'open_beta_users') {
      if (!userCache.has(uid)) {
        const userSnap = await db.collection('users').doc(uid).get();
        userCache.set(uid, userSnap.data() || {});
      }
      if (!userMatchesAudience({ audience, userData: userCache.get(uid) })) {
        continue;
      }
    }

    seenTokens.add(token);
    userIds.add(uid);
    targets.push({ token, ref: doc.ref, legacy: false, uid });
  }

  return { targets, userIds: Array.from(userIds), skippedByPreference };
}

async function createInAppNotifications({ data, userIds, broadcastId }) {
  let created = 0;
  for (let i = 0; i < userIds.length; i += 450) {
    const batch = db.batch();
    const chunk = userIds.slice(i, i + 450);
    chunk.forEach((uid) => {
      const ref = db.collection('trading_notifications').doc(`${broadcastId}_${uid}`);
      batch.set(ref, {
        id: ref.id,
        broadcastId,
        broadcastPushHandled: true,
        targetUid: uid,
        actorUid: normalizeString(data.senderUid) || 'system',
        title: normalizeString(data.title),
        body: normalizeString(data.body),
        type: normalizeString(data.type || 'announcement'),
        listingId: '',
        offerId: '',
        sessionId: '',
        watchId: '',
        queueId: '',
        preparationId: '',
        opportunityId: '',
        route: normalizeString(data.route),
        deepLink: normalizeString(data.deepLink),
        imageUrl: normalizeString(data.imageUrl),
        entityId: normalizeString(data.entityId),
        audience: normalizeString(data.audience),
        priority: normalizeString(data.priority || 'normal'),
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    await batch.commit();
    created += chunk.length;
  }
  return created;
}

function timestampMillis(value) {
  if (!value) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : parsed;
  }
  return null;
}

function safeIdComponent(value) {
  const normalized = normalizeString(value).toLowerCase();
  return (normalized || 'unknown').replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '') || 'unknown';
}

function sessionScheduleId({ kind, sessionId, targetUid, phase }) {
  return ['uag', kind, safeIdComponent(sessionId), safeIdComponent(targetUid), phase].join('_');
}

function readSessionKind(value) {
  const normalized = normalizeString(value).toLowerCase();
  if (normalized === 'match' || normalized === 'match_rider' || normalized === 'matchmaking') return 'matchmaking';
  if (normalized === 'raid' || normalized === 'planner') return 'raid';
  return 'trade';
}

function sessionKindLabel(kind) {
  switch (kind) {
    case 'matchmaking':
      return 'Matchmaking';
    case 'raid':
      return 'Raid';
    case 'trade':
    default:
      return 'Trade';
  }
}

function sessionIsTerminal(status) {
  const normalized = normalizeString(status).toLowerCase();
  return normalized === 'completed' ||
    normalized === 'no_show' ||
    normalized === 'noshow' ||
    normalized === 'cancelled' ||
    normalized === 'canceled' ||
    normalized === 'betrayal';
}

function preSessionBody(kind, otherName) {
  const withText = otherName ? ` with ${otherName}` : '';
  if (kind === 'matchmaking') {
    return `Your Match Rider squad-up${withText} starts in 15 minutes. Open the session to get ready.`;
  }
  if (kind === 'raid') {
    return `Your planned ARC Raiders run${withText} starts in 15 minutes. Open the planner to get ready.`;
  }
  return `Your ARC Raiders trade${withText} starts in 15 minutes. Open the session to confirm or rearrange.`;
}

function feedbackTitle(kind) {
  if (kind === 'matchmaking') return 'How did the squad-up go?';
  if (kind === 'raid') return 'How did the raid go?';
  return 'How did the trade go?';
}

function feedbackBody(kind) {
  if (kind === 'matchmaking') {
    return 'Share a quick rating, no-show or issue report so Match Rider learns from the session.';
  }
  if (kind === 'raid') {
    return 'Log the result, no-show or support issue so your planned run history stays accurate.';
  }
  return 'Confirm completed, no-show or issues so UAG can protect session quality.';
}

function feedbackAction(kind) {
  if (kind === 'matchmaking') return 'submit_match_feedback';
  if (kind === 'raid') return 'submit_raid_feedback';
  return 'confirm_trade_outcome';
}

function buildSessionSchedules({
  sessionId,
  kind,
  targetUid,
  startMillis,
  route,
  deepLink,
  otherParticipantName = '',
  listingId = '',
  offerId = '',
  location = 'ARC Raiders',
}) {
  const label = sessionKindLabel(kind);
  const endMillis = startMillis + 60 * 60 * 1000;
  const sharedMetadata = {
    sessionId,
    sessionKind: kind,
    otherParticipantName: normalizeString(otherParticipantName),
    locationPlatform: normalizeString(location),
    startsAt: new Date(startMillis).toISOString(),
    endsAt: new Date(endMillis).toISOString(),
  };

  return [
    {
      id: sessionScheduleId({ kind, sessionId, targetUid, phase: 'pre_session' }),
      targetUid,
      actorUid: 'system',
      type: 'reminder',
      title: `${label} starts in 15 minutes`,
      body: preSessionBody(kind, normalizeString(otherParticipantName)),
      dueAt: admin.firestore.Timestamp.fromMillis(startMillis - 15 * 60 * 1000),
      route,
      deepLink,
      entityId: sessionId,
      sessionId,
      listingId,
      offerId,
      priority: 'high',
      status: 'queued',
      deliveryChannels: ['push', 'in_app'],
      metadata: { ...sharedMetadata, phase: 'pre_session' },
    },
    {
      id: sessionScheduleId({ kind, sessionId, targetUid, phase: 'post_session_feedback' }),
      targetUid,
      actorUid: 'system',
      type: 'post_session_feedback',
      title: feedbackTitle(kind),
      body: feedbackBody(kind),
      dueAt: admin.firestore.Timestamp.fromMillis(endMillis + 15 * 60 * 1000),
      route,
      deepLink,
      entityId: sessionId,
      sessionId,
      listingId,
      offerId,
      priority: 'normal',
      status: 'queued',
      deliveryChannels: ['push', 'in_app'],
      metadata: {
        ...sharedMetadata,
        phase: 'post_session_feedback',
        recommendedAction: feedbackAction(kind),
      },
    },
  ];
}

async function upsertSessionSchedules(scheduleInputs) {
  if (!scheduleInputs.length) return;
  const batch = db.batch();
  scheduleInputs.forEach((schedule) => {
    const ref = db.collection('uag_notification_schedules').doc(schedule.id);
    batch.set(ref, {
      ...schedule,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  await batch.commit();
}

async function cancelSessionSchedules({ sessionId, kind, targetUids }) {
  const uniqueTargets = Array.from(new Set(targetUids.map(normalizeString).filter(Boolean)));
  if (!uniqueTargets.length) return;
  const batch = db.batch();
  uniqueTargets.forEach((targetUid) => {
    ['pre_session', 'post_session_feedback'].forEach((phase) => {
      const id = sessionScheduleId({ kind, sessionId, targetUid, phase });
      batch.set(db.collection('uag_notification_schedules').doc(id), {
        id,
        targetUid,
        sessionId,
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  });
  await batch.commit();
}

function participantsForTradingSession(data) {
  const traderOneUid = normalizeString(data.traderOneUid);
  const traderTwoUid = normalizeString(data.traderTwoUid);
  return [
    {
      uid: traderOneUid,
      otherUid: traderTwoUid,
      otherName: normalizeString(data.traderTwoName),
    },
    {
      uid: traderTwoUid,
      otherUid: traderOneUid,
      otherName: normalizeString(data.traderOneName),
    },
  ].filter((participant) => participant.uid && participant.uid !== participant.otherUid);
}

function participantsForUagSession(data) {
  const participantOneUid = normalizeString(data.participantOneUid);
  const participantTwoUid = normalizeString(data.participantTwoUid);
  return [
    {
      uid: participantOneUid,
      otherUid: participantTwoUid,
      otherName: normalizeString(data.participantTwoDisplayName),
    },
    {
      uid: participantTwoUid,
      otherUid: participantOneUid,
      otherName: normalizeString(data.participantOneDisplayName),
    },
  ].filter((participant) => participant.uid && participant.uid !== participant.otherUid);
}

async function syncTradingSessionSchedules(event) {
  const sessionId = event.params.sessionId;
  const after = event.data?.after;
  const beforeData = event.data?.before?.data() || {};
  const afterData = after?.exists ? after.data() || {} : null;
  const fallbackParticipants = participantsForTradingSession(afterData || beforeData);

  if (!afterData) {
    await cancelSessionSchedules({
      sessionId,
      kind: 'trade',
      targetUids: fallbackParticipants.map((participant) => participant.uid),
    });
    return;
  }

  const startMillis =
    timestampMillis(afterData.selectedBooking) ||
    timestampMillis(afterData.scheduledAt);
  const participants = participantsForTradingSession(afterData);
  if (!startMillis || !participants.length || sessionIsTerminal(afterData.status)) {
    await cancelSessionSchedules({
      sessionId,
      kind: 'trade',
      targetUids: participants.length
        ? participants.map((participant) => participant.uid)
        : fallbackParticipants.map((participant) => participant.uid),
    });
    return;
  }

  const schedules = participants.flatMap((participant) => buildSessionSchedules({
    sessionId,
    kind: 'trade',
    targetUid: participant.uid,
    startMillis,
    route: '/trading-hub/arc-raiders/sessions',
    deepLink: '/trading-hub/arc-raiders/sessions',
    otherParticipantName: participant.otherName,
    listingId: normalizeString(afterData.listingId),
    offerId: normalizeString(afterData.offerId),
    location: 'ARC Raiders trade session',
  }));
  await upsertSessionSchedules(schedules);
}

async function syncUagSessionSchedules(event) {
  const sessionId = event.params.sessionId;
  const after = event.data?.after;
  const beforeData = event.data?.before?.data() || {};
  const afterData = after?.exists ? after.data() || {} : null;
  const kind = readSessionKind((afterData || beforeData).type);
  const fallbackParticipants = participantsForUagSession(afterData || beforeData);

  if (!afterData) {
    await cancelSessionSchedules({
      sessionId,
      kind,
      targetUids: fallbackParticipants.map((participant) => participant.uid),
    });
    return;
  }

  const startMillis = timestampMillis(afterData.scheduledAt);
  const participants = participantsForUagSession(afterData);
  if (!startMillis || !participants.length || sessionIsTerminal(afterData.status)) {
    await cancelSessionSchedules({
      sessionId,
      kind,
      targetUids: participants.length
        ? participants.map((participant) => participant.uid)
        : fallbackParticipants.map((participant) => participant.uid),
    });
    return;
  }

  const route = '/trading-hub/arc-raiders/session-planner';
  const schedules = participants.flatMap((participant) => buildSessionSchedules({
    sessionId,
    kind,
    targetUid: participant.uid,
    startMillis,
    route,
    deepLink: route,
    otherParticipantName: participant.otherName,
    listingId: normalizeString(afterData.tradeListingId),
    offerId: '',
    location: 'ARC Raiders',
  }));
  await upsertSessionSchedules(schedules);
}

async function schedulePreferencesAllow(targetUid, type) {
  const snap = await db
    .collection('users')
    .doc(targetUid)
    .collection('notification_preferences')
    .doc('current')
    .get();
  return preferencesAllowType(snap.data() || {}, type);
}

async function processScheduleDoc(ref) {
  const now = admin.firestore.Timestamp.now();
  const schedule = await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);
    if (!snap.exists) return null;
    const data = snap.data() || {};
    if (normalizeString(data.status) !== 'queued') return null;
    const dueMillis = timestampMillis(data.dueAt);
    if (!dueMillis || dueMillis > now.toMillis()) return null;
    transaction.set(ref, {
      status: 'processing',
      processingAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ...data, id: normalizeString(data.id || snap.id) };
  });

  if (!schedule) return { processed: false, status: 'skipped' };

  try {
    const targetUid = normalizeString(schedule.targetUid);
    const type = normalizeString(schedule.type);
    if (!targetUid || !normalizeString(schedule.title) || !normalizeString(schedule.body)) {
      throw new Error('Schedule is missing targetUid, title or body.');
    }

    if (!(await schedulePreferencesAllow(targetUid, type))) {
      await ref.set({
        status: 'skipped_preference',
        skippedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return { processed: true, status: 'skipped_preference' };
    }

    const dueMillis = timestampMillis(schedule.dueAt) || Date.now();
    const notificationId = `${schedule.id}_${dueMillis}`;
    const notificationRef = db.collection('trading_notifications').doc(notificationId);
    const existing = await notificationRef.get();
    if (!existing.exists) {
      await notificationRef.set({
        id: notificationId,
        scheduledNotificationId: schedule.id,
        targetUid,
        actorUid: normalizeString(schedule.actorUid) || 'system',
        title: normalizeString(schedule.title),
        body: normalizeString(schedule.body),
        type,
        listingId: normalizeString(schedule.listingId),
        offerId: normalizeString(schedule.offerId),
        sessionId: normalizeString(schedule.sessionId || schedule.entityId),
        watchId: '',
        queueId: '',
        preparationId: '',
        opportunityId: '',
        route: normalizeString(schedule.route),
        deepLink: normalizeString(schedule.deepLink || schedule.route),
        imageUrl: normalizeString(schedule.imageUrl),
        entityId: normalizeString(schedule.entityId),
        audience: 'specific_user',
        priority: normalizeString(schedule.priority || 'normal'),
        metadata: schedule.metadata || {},
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await ref.set({
      status: 'sent',
      notificationId,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { processed: true, status: existing.exists ? 'duplicate_skipped' : 'sent' };
  } catch (error) {
    console.error('Scheduled notification processing failed', error);
    await ref.set({
      status: 'failed',
      error: error.message || String(error),
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { processed: true, status: 'failed' };
  }
}

exports.syncTradingSessionNotificationSchedules = onDocumentWritten(
  'trading_sessions/{sessionId}',
  syncTradingSessionSchedules
);

exports.syncUagSessionNotificationSchedules = onDocumentWritten(
  'uag_sessions/{sessionId}',
  syncUagSessionSchedules
);

exports.processUagNotificationSchedules = onSchedule(
  {
    schedule: 'every 5 minutes',
    timeZone: 'Europe/London',
  },
  async () => {
    const dueSnap = await db.collection('uag_notification_schedules')
      .where('status', '==', 'queued')
      .where('dueAt', '<=', admin.firestore.Timestamp.now())
      .orderBy('dueAt', 'asc')
      .limit(100)
      .get();

    const results = [];
    for (const doc of dueSnap.docs) {
      results.push(await processScheduleDoc(doc.ref));
    }
    console.log('Processed UAG notification schedules', {
      due: dueSnap.size,
      sent: results.filter((result) => result.status === 'sent').length,
      skipped: results.filter((result) => result.status === 'skipped_preference').length,
      failed: results.filter((result) => result.status === 'failed').length,
    });
  }
);

exports.sendTradingNotificationPush = onDocumentCreated(
  'trading_notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() || {};
    if (data.broadcastPushHandled === true) return;
    const targetUid = data.targetUid;
    if (!targetUid) return;

    const targets = await loadUserPushTargets(targetUid, data.type);
    if (!targets.length) return;
    await sendToTargets({
      notificationData: { ...data, id: snap.id },
      targets,
    });
  }
);

exports.sendUagNotificationBroadcast = onDocumentCreated(
  'notification_broadcasts/{broadcastId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const broadcastId = event.params.broadcastId;
    const ref = snap.ref;
    const data = snap.data() || {};
    const senderUid = normalizeString(data.senderUid);

    if (normalizeString(data.status) !== 'queued') return;
    if (!(await isAdminUser(senderUid))) {
      await ref.set({
        status: 'rejected',
        error: 'Admin privileges are required.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }
    if (!normalizeString(data.title) || !normalizeString(data.body)) {
      await ref.set({
        status: 'rejected',
        error: 'Title and body are required.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }

    const claimed = await db.runTransaction(async (transaction) => {
      const current = await transaction.get(ref);
      const currentData = current.data() || {};
      if (normalizeString(currentData.status) !== 'queued') return false;
      transaction.set(ref, {
        status: 'sending',
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return true;
    });
    if (!claimed) return;

    const delivery = {
      attempted: 0,
      successful: 0,
      failed: 0,
      invalidTokens: 0,
      skippedByPreference: 0,
      inAppCreated: 0,
      eligibleUsers: 0,
      eligibleDevices: 0,
    };

    try {
      const { targets, userIds, skippedByPreference } = await loadBroadcastTargets(data);
      delivery.eligibleDevices = targets.length;
      delivery.eligibleUsers = userIds.length;
      delivery.skippedByPreference = skippedByPreference;

      if (data.createInApp !== false) {
        delivery.inAppCreated = await createInAppNotifications({
          data,
          userIds,
          broadcastId,
        });
      }

      if (data.sendPush !== false && targets.length > 0) {
        const pushTotals = await sendToTargets({
          notificationData: { ...data, id: broadcastId },
          targets,
        });
        Object.assign(delivery, {
          ...delivery,
          attempted: pushTotals.attempted,
          successful: pushTotals.successful,
          failed: pushTotals.failed,
          invalidTokens: pushTotals.invalidTokens,
        });
      }

      const finalStatus = delivery.failed > 0 ? 'partial_failed' : 'sent';
      await db.collection('notification_delivery_reports').doc(broadcastId).set({
        id: broadcastId,
        broadcastId,
        senderUid,
        type: normalizeString(data.type),
        audience: normalizeString(data.audience),
        testMode: data.testMode === true,
        ...delivery,
        status: finalStatus,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await ref.set({
        status: finalStatus,
        delivery,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch (error) {
      console.error('Broadcast delivery failed', error);
      await db.collection('notification_delivery_reports').doc(broadcastId).set({
        id: broadcastId,
        broadcastId,
        senderUid,
        status: 'failed',
        error: error.message || String(error),
        ...delivery,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await ref.set({
        status: 'failed',
        error: error.message || String(error),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
);
