const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const Stripe = require('stripe');

admin.initializeApp();

const db = admin.firestore();

function stripeClient() {
  const secret = process.env.STRIPE_SECRET_KEY;
  if (!secret) {
    throw new HttpsError('failed-precondition', 'STRIPE_SECRET_KEY is not configured.');
  }
  return new Stripe(secret, { apiVersion: '2024-06-20' });
}

function priceIdFor(plan, interval) {
  const key = `STRIPE_PRICE_${String(plan).toUpperCase()}_${String(interval).toUpperCase()}`;
  const value = process.env[key];
  if (!value) {
    throw new HttpsError('failed-precondition', `${key} is not configured.`);
  }
  return value;
}

function planMeta(plan) {
  if (plan === 'premium') {
    return { tier: 'premium', discountPercent: 20, commissionPercent: 20 };
  }
  if (plan === 'essential') {
    return { tier: 'essential', discountPercent: 10, commissionPercent: 10 };
  }
  throw new HttpsError('invalid-argument', 'Unsupported plan.');
}

async function getOrCreateStripeCustomer(uid, email) {
  const ref = db.collection('stripe_customers').doc(uid);
  const snap = await ref.get();
  if (snap.exists && snap.data().customerId) return snap.data().customerId;

  const stripe = stripeClient();
  const customer = await stripe.customers.create({
    email: email || undefined,
    metadata: { uid },
  });

  await ref.set({
    uid,
    customerId: customer.id,
    email: email || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  return customer.id;
}

exports.createStripeCheckoutSession = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');

  const uid = request.auth.uid;
  const email = request.auth.token.email;
  const plan = String(request.data.plan || '').toLowerCase();
  const interval = String(request.data.interval || 'monthly').toLowerCase();
  const referralCode = request.data.referralCode ? String(request.data.referralCode).trim().toUpperCase() : null;
  const successUrl = String(request.data.successUrl || process.env.STRIPE_SUCCESS_URL || 'https://unite-a-gamer.web.app/');
  const cancelUrl = String(request.data.cancelUrl || process.env.STRIPE_CANCEL_URL || 'https://unite-a-gamer.web.app/');

  const meta = planMeta(plan);
  const stripe = stripeClient();
  const customerId = await getOrCreateStripeCustomer(uid, email);

  let referrerUid = null;
  let discountPercent = 0;
  if (referralCode) {
    const referralSnap = await db.collection('referral_codes').doc(referralCode).get();
    if (referralSnap.exists && referralSnap.data().active !== false) {
      referrerUid = referralSnap.data().ownerUid || null;
      if (referrerUid && referrerUid !== uid) {
        discountPercent = Number(referralSnap.data().discountPercent || meta.discountPercent || 0);
      }
    }
  }

  let discounts = undefined;
  if (discountPercent > 0) {
    const coupon = await stripe.coupons.create({
      duration: 'repeating',
      duration_in_months: 12,
      percent_off: discountPercent,
      name: `UAG ${discountPercent}% referral discount`,
      metadata: { referralCode: referralCode || '', referrerUid: referrerUid || '' },
    });
    discounts = [{ coupon: coupon.id }];
  }

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    customer: customerId,
    line_items: [{ price: priceIdFor(plan, interval), quantity: 1 }],
    success_url: successUrl,
    cancel_url: cancelUrl,
    discounts,
    subscription_data: {
      metadata: {
        uid,
        tier: meta.tier,
        referralCode: referralCode || '',
        referrerUid: referrerUid || '',
        referralDiscountPercent: String(discountPercent || 0),
        referralCommissionPercent: String(meta.commissionPercent),
      },
    },
    metadata: {
      uid,
      tier: meta.tier,
      referralCode: referralCode || '',
      referrerUid: referrerUid || '',
    },
  });

  return { url: session.url };
});

exports.createStripePortalSession = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
  const uid = request.auth.uid;
  const snap = await db.collection('stripe_customers').doc(uid).get();
  const customerId = snap.data() && snap.data().customerId;
  if (!customerId) throw new HttpsError('not-found', 'Stripe customer not found.');

  const stripe = stripeClient();
  const session = await stripe.billingPortal.sessions.create({
    customer: customerId,
    return_url: String(request.data.returnUrl || process.env.STRIPE_PORTAL_RETURN_URL || 'https://unite-a-gamer.web.app/'),
  });
  return { url: session.url };
});

exports.stripeWebhook = onRequest(async (req, res) => {
  const signature = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    res.status(500).send('STRIPE_WEBHOOK_SECRET is not configured.');
    return;
  }

  let event;
  try {
    event = stripeClient().webhooks.constructEvent(req.rawBody, signature, webhookSecret);
  } catch (err) {
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  try {
    if (event.type === 'checkout.session.completed') {
      await handleCheckoutCompleted(event.data.object);
    }
    if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated') {
      await handleSubscriptionUpsert(event.data.object);
    }
    if (event.type === 'customer.subscription.deleted') {
      await handleSubscriptionDeleted(event.data.object);
    }
    if (event.type === 'invoice.paid') {
      await handleInvoicePaid(event.data.object);
    }
    res.json({ received: true });
  } catch (err) {
    console.error(err);
    res.status(500).send('Webhook handling failed.');
  }
});

async function handleCheckoutCompleted(session) {
  const uid = session.metadata && session.metadata.uid;
  if (!uid) return;
  await db.collection('users').doc(uid).set({
    stripeCustomerId: session.customer || null,
    subscriptionTier: session.metadata.tier || 'free',
    subscriptionStatus: 'checkout_completed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function handleSubscriptionUpsert(subscription) {
  const uid = subscription.metadata && subscription.metadata.uid;
  if (!uid) return;
  const tier = subscription.metadata.tier || 'free';
  const currentPeriodEnd = subscription.current_period_end
    ? admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000)
    : null;

  await db.collection('users').doc(uid).set({
    subscriptionTier: tier,
    subscriptionStatus: subscription.status,
    stripeSubscriptionId: subscription.id,
    subscriptionCurrentPeriodEnd: currentPeriodEnd,
    referralDiscountPercent: Number(subscription.metadata.referralDiscountPercent || 0),
    referralCommissionPercent: tier === 'premium' ? 20 : tier === 'essential' ? 10 : 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('users').doc(uid).collection('subscription_events').doc(subscription.id).set({
    type: 'subscription_upsert',
    subscriptionId: subscription.id,
    tier,
    status: subscription.status,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function handleSubscriptionDeleted(subscription) {
  const uid = subscription.metadata && subscription.metadata.uid;
  if (!uid) return;
  await db.collection('users').doc(uid).set({
    subscriptionTier: 'free',
    subscriptionStatus: 'cancelled',
    stripeSubscriptionId: subscription.id,
    referralDiscountPercent: 0,
    referralCommissionPercent: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function handleInvoicePaid(invoice) {
  const subscriptionId = invoice.subscription;
  if (!subscriptionId) return;
  const stripe = stripeClient();
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const uid = subscription.metadata && subscription.metadata.uid;
  const referrerUid = subscription.metadata && subscription.metadata.referrerUid;
  if (!uid || !referrerUid || uid === referrerUid) return;

  const tier = subscription.metadata.tier || 'free';
  const commissionPercent = Number(subscription.metadata.referralCommissionPercent || (tier === 'premium' ? 20 : tier === 'essential' ? 10 : 0));
  if (commissionPercent <= 0) return;

  const paid = Number(invoice.amount_paid || 0);
  const commissionPence = Math.floor(paid * commissionPercent / 100);
  if (commissionPence <= 0) return;

  const eventId = invoice.id;
  const eventRef = db.collection('referral_events').doc(eventId);
  const eventSnap = await eventRef.get();
  if (eventSnap.exists) return;

  const releaseAt = admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000);
  const referrerRef = db.collection('users').doc(referrerUid);

  await db.runTransaction(async (tx) => {
    tx.set(eventRef, {
      id: eventId,
      referredUid: uid,
      referrerUid,
      subscriptionId,
      invoiceId: invoice.id,
      tier,
      amountPaidPence: paid,
      commissionPercent,
      commissionPence,
      status: 'pending',
      releaseAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(referrerRef, {
      referralPendingBalancePence: admin.firestore.FieldValue.increment(commissionPence),
      referralTotalEarnedPence: admin.firestore.FieldValue.increment(commissionPence),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
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
        title: data.title || 'UAG Traders Hub',
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
