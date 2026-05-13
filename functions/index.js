const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onRequest } = require('firebase-functions/v2/https');
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

exports.sendTradingNotificationPush = onDocumentCreated(
  'trading_notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() || {};
    const targetUid = data.targetUid;
    if (!targetUid) return;

    const tokensSnap = await db
      .collection('users')
      .doc(targetUid)
      .collection('notification_tokens')
      .get();

    const tokens = tokensSnap.docs
      .map((doc) => doc.id || doc.data().token)
      .filter(Boolean);

    if (!tokens.length) return;

    const response = await admin.messaging().sendEachForMulticast({
      notification: {
        title: data.title || 'UAG ARC Raiders Hub',
        body: data.body || 'You have a new trading update.',
      },
      data: {
        type: String(data.type || ''),
        listingId: String(data.listingId || ''),
        offerId: String(data.offerId || ''),
        sessionId: String(data.sessionId || ''),
        notificationId: snap.id,
      },
      tokens,
    });

    const batch = db.batch();
    response.responses.forEach((result, index) => {
      if (!result.success) {
        const code = result.error && result.error.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          batch.delete(
            db
              .collection('users')
              .doc(targetUid)
              .collection('notification_tokens')
              .doc(tokens[index])
          );
        }
      }
    });

    await batch.commit();
  }
);
