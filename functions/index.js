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
    kind: 'core',
    tier: 'essential',
    billingPeriod: 'monthly',
    pricePence: 799,
    stripePriceEnv: 'STRIPE_PRICE_ESSENTIAL_MONTHLY',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'essential',
  },
  essential_yearly: {
    kind: 'core',
    tier: 'essential',
    billingPeriod: 'yearly',
    pricePence: 6999,
    inlinePrice: true,
    checkoutLabel: 'UAG Essential Annual',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'essential',
  },
  premium_monthly: {
    kind: 'core',
    tier: 'premium',
    billingPeriod: 'monthly',
    pricePence: 999,
    stripePriceEnv: 'STRIPE_PRICE_PREMIUM_MONTHLY',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium',
  },
  premium_yearly: {
    kind: 'core',
    tier: 'premium',
    billingPeriod: 'yearly',
    pricePence: 8999,
    inlinePrice: true,
    checkoutLabel: 'UAG Premium Annual',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium',
  },
  beta_premium_monthly: {
    kind: 'core',
    tier: 'premium',
    billingPeriod: 'monthly',
    pricePence: 699,
    inlinePrice: true,
    offerAudience: 'beta',
    offerId: 'closed_beta_monthly',
    checkoutLabel: 'UAG Closed Beta Premium Monthly',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium',
  },
  beta_premium_yearly: {
    kind: 'core',
    tier: 'premium',
    billingPeriod: 'yearly',
    pricePence: 4999,
    inlinePrice: true,
    offerAudience: 'beta',
    offerId: 'closed_beta_yearly',
    checkoutLabel: 'UAG Closed Beta Premium Annual',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium',
  },
  founding_raider_premium_yearly: {
    kind: 'core',
    tier: 'premium',
    billingPeriod: 'yearly',
    pricePence: 2999,
    inlinePrice: true,
    offerAudience: 'founder',
    offerId: 'founding_raider_lifetime_rate',
    checkoutLabel: 'UAG Founding Raider Premium Annual',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium',
  },
  premium_pass_day: {
    kind: 'pass',
    tier: 'premium',
    billingPeriod: 'pass_24_hour',
    pricePence: 199,
    inlinePrice: true,
    passType: 'day24',
    passDurationHours: 24,
    checkoutLabel: 'UAG 24-Hour Premium Pass',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium_passes',
  },
  premium_pass_week: {
    kind: 'pass',
    tier: 'premium',
    billingPeriod: 'pass_7_day',
    pricePence: 349,
    inlinePrice: true,
    passType: 'week7',
    passDurationHours: 168,
    checkoutLabel: 'UAG 7-Day Premium Pass',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium_passes',
  },
  beta_premium_pass_day: {
    kind: 'pass',
    tier: 'premium',
    billingPeriod: 'pass_24_hour',
    pricePence: 149,
    inlinePrice: true,
    offerAudience: 'beta',
    offerId: 'closed_beta_pass_day',
    passType: 'day24',
    passDurationHours: 24,
    checkoutLabel: 'UAG Closed Beta 24-Hour Premium Pass',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium_passes',
  },
  beta_premium_pass_week: {
    kind: 'pass',
    tier: 'premium',
    billingPeriod: 'pass_7_day',
    pricePence: 249,
    inlinePrice: true,
    offerAudience: 'beta',
    offerId: 'closed_beta_pass_week',
    passType: 'week7',
    passDurationHours: 168,
    checkoutLabel: 'UAG Closed Beta 7-Day Premium Pass',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'premium_passes',
  },
  founding_supporter_monthly: {
    kind: 'supporter',
    tier: 'supporter',
    billingPeriod: 'monthly',
    pricePence: 399,
    minimumPricePence: 299,
    maximumPricePence: 499,
    stripePriceEnv: 'STRIPE_PRICE_FOUNDING_SUPPORTER_MONTHLY',
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    impactPotId: 'supporter',
    futureDiscountPercent: 15,
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

function truthy(value) {
  if (value === true) return true;
  if (typeof value === 'number') return value !== 0;
  const text = String(value || '').trim().toLowerCase();
  return text === 'true' || text === '1' || text === 'yes';
}

function isClosedBetaUser(recognitionData) {
  const beta = recognitionData?.beta || {};
  return truthy(recognitionData?.betaTester) ||
    truthy(recognitionData?.closedBetaParticipant) ||
    truthy(beta.participant) ||
    truthy(beta.pricingEligible);
}

function isFoundingRaider(recognitionData) {
  const founderStatus = recognitionData?.founderStatus || {};
  return truthy(recognitionData?.foundingRaider) ||
    truthy(recognitionData?.founder) ||
    truthy(founderStatus.active);
}

function founderRateForfeited(recognitionData) {
  const founderStatus = recognitionData?.founderStatus || {};
  return truthy(recognitionData?.founderRateForfeited) ||
    truthy(founderStatus.rateForfeited);
}

function timestampMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  const parsed = Date.parse(String(value));
  return Number.isFinite(parsed) ? parsed : 0;
}

function currentPremiumPass(userData) {
  return userData?.monetisation?.premiumPass || userData?.premiumPass || {};
}

async function loadCommercialRecognition(uid) {
  const snapshot = await db.collection('uag_commercial_recognition').doc(uid).get();
  return snapshot.exists ? (snapshot.data() || {}) : {};
}

function activeCoreSubscription(userData) {
  const monetisation = userData?.monetisation || {};
  const status = String(
    monetisation.subscriptionStatus || userData?.subscriptionStatus || '',
  ).trim().toLowerCase();
  const tier = String(
    monetisation.tier || userData?.tier || userData?.subscriptionTier || '',
  ).trim().toLowerCase();
  return {
    active: status === 'active' || status === 'trialing',
    tier,
  };
}

function assertPlanEligibility(plan, userData, recognitionData) {
  const core = activeCoreSubscription(userData);
  if (plan.kind === 'core' && core.active) {
    const error = new Error('An active UAG subscription already exists on this account. Manage the current subscription before starting another.');
    error.statusCode = 409;
    throw error;
  }
  if (plan.kind === 'pass' && core.active && core.tier === 'premium') {
    const error = new Error('Premium is already active on this account.');
    error.statusCode = 409;
    throw error;
  }
  if (plan.offerAudience === 'beta' && !isClosedBetaUser(recognitionData)) {
    const error = new Error('This Closed Beta price is not available on this account.');
    error.statusCode = 403;
    throw error;
  }
  if (plan.offerAudience === 'founder') {
    if (!isFoundingRaider(recognitionData)) {
      const error = new Error('This Founding Raider price is not available on this account.');
      error.statusCode = 403;
      throw error;
    }
    if (founderRateForfeited(recognitionData)) {
      const error = new Error('The Founding Raider lifetime rate was forfeited when the previous Founder subscription ended.');
      error.statusCode = 403;
      throw error;
    }
  }
  if (plan.kind === 'pass') {
    const pass = currentPremiumPass(userData);
    const activeUntil = timestampMillis(pass.expiresAt);
    if (activeUntil > Date.now()) {
      const error = new Error('A Premium pass is already active on this account.');
      error.statusCode = 409;
      throw error;
    }
  }
}

function safeCheckoutReturnUrl(value) {
  const fallback = 'https://unite-a-gamer.web.app/';
  try {
    const url = new URL(String(value || fallback));
    const allowed = url.origin === 'https://unite-a-gamer.web.app' ||
      url.origin === 'https://unite-a-gamer.firebaseapp.com' ||
      /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(url.origin);
    return allowed ? url.toString() : fallback;
  } catch (_) {
    return fallback;
  }
}

function checkoutLineItem(plan, planId, configuredPriceId) {
  if (configuredPriceId && !plan.inlinePrice) {
    return { price: configuredPriceId, quantity: 1 };
  }
  const priceData = {
    currency: 'gbp',
    unit_amount: plan.pricePence,
    product_data: {
      name: plan.checkoutLabel || `UAG ${plan.tier} ${plan.billingPeriod}`,
      metadata: {
        uagPlanId: planId,
        uagOfferId: plan.offerId || '',
      },
    },
  };
  if (plan.kind === 'core') {
    priceData.recurring = {
      interval: plan.billingPeriod === 'yearly' ? 'year' : 'month',
    };
  }
  return { price_data: priceData, quantity: 1 };
}

function setCheckoutCors(req, res) {
  const origin = String(req.headers.origin || '');
  const allowed = origin === 'https://unite-a-gamer.web.app' ||
    origin === 'https://unite-a-gamer.firebaseapp.com' ||
    /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  if (allowed) res.set('Access-Control-Allow-Origin', origin);
  res.set('Vary', 'Origin');
  res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return true;
  }
  return false;
}

async function resolveReferral(referralCode) {
  const code = String(referralCode || '').trim().toUpperCase();
  if (!code) return null;

  const [creatorCodeSnap, communityCodeSnap] = await Promise.all([
    db.collection('uag_creator_campaign_code_requests').doc(code).get(),
    db.collection('uag_community_referral_codes').doc(code).get(),
  ]);

  if (creatorCodeSnap.exists) {
    const creatorCode = creatorCodeSnap.data() || {};
    if (
      creatorCode.status === 'approved' &&
      creatorCode.uid &&
      String(creatorCode.code || '').trim().toUpperCase() === code
    ) {
      const requestedDiscountPercent = Number(
        creatorCode.subscriberDiscountPercent || 0,
      );
      const subscriberDiscountPercent =
        Number.isFinite(requestedDiscountPercent) &&
        requestedDiscountPercent > 0 &&
        requestedDiscountPercent <= 50
          ? requestedDiscountPercent
          : 10;

      return {
        code,
        ownerUid: creatorCode.uid,
        source: 'uag_creator_programme',
        subscriberDiscountPercent,
        subscriberDiscountDuration:
          creatorCode.subscriberDiscountDuration === 'forever'
            ? 'forever'
            : 'once',
      };
    }
  }

  if (communityCodeSnap.exists) {
    const communityCode = communityCodeSnap.data() || {};
    const ownerUid = normalizeString(communityCode.ownerUid);
    const canonical = normalizeString(communityCode.code).toUpperCase();
    if (ownerUid && canonical === code) {
      return {
        code,
        ownerUid,
        source: 'uag_community_referral',
        subscriberDiscountPercent: 10,
        subscriberDiscountDuration: 'once',
      };
    }
  }

  return null;
}

async function approvedCreatorProgrammeApplication(uid) {
  const snapshot = await db
    .collection('uag_creator_applications')
    .where('uid', '==', uid)
    .where('status', '==', 'approved')
    .limit(1)
    .get();
  return snapshot.empty ? null : snapshot.docs[0].data();
}

exports.createUagCheckoutSession = onRequest({ secrets: [stripeSecretKey] }, async (req, res) => {
  try {
    if (setCheckoutCors(req, res)) return;
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const authHeader = req.headers.authorization || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!idToken) {
      res.status(401).json({ error: 'Sign in before starting checkout.' });
      return;
    }
    const decoded = await admin.auth().verifyIdToken(idToken);
    const uid = decoded.uid;

    const { planId, referralCode, successUrl, cancelUrl } = req.body || {};
    const plan = getPlan(planId);
    const priceId = plan.stripePriceEnv ? process.env[plan.stripePriceEnv] : null;
    if (plan.stripePriceEnv && !priceId) {
      throw new Error(`Missing Stripe price env: ${plan.stripePriceEnv}`);
    }

    const userRef = db.collection('users').doc(uid);
    const creatorAttributionRef = userRef
      .collection('monetisation_usage')
      .doc('creator_attribution');
    const communityAttributionRef = userRef
      .collection('monetisation_usage')
      .doc('community_referral_attribution');
    const [
      userSnap,
      recognitionData,
      creatorAttributionSnap,
      communityAttributionSnap,
    ] = await Promise.all([
      userRef.get(),
      loadCommercialRecognition(uid),
      creatorAttributionRef.get(),
      communityAttributionRef.get(),
    ]);
    const userData = userSnap.data() || {};
    const creatorAttribution = creatorAttributionSnap.data() || {};
    const communityAttribution = communityAttributionSnap.data() || {};
    if (userData.ageVerification?.verifiedOver18 !== true) {
      res.status(403).json({
        error: '18+ verification is required before starting a paid subscription.',
      });
      return;
    }
    assertPlanEligibility(plan, userData, recognitionData);

    let customerId = userData?.monetisation?.stripeCustomerId || userData.stripeCustomerId;
    const stripe = stripeClient();

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: decoded.email || undefined,
        metadata: { uid },
      });
      customerId = customer.id;
      await userRef.set({
        monetisation: {
          stripeCustomerId: customerId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });
    }

    const effectiveReferralCode = String(
      referralCode ||
      creatorAttribution.code ||
      communityAttribution.code ||
      userData.referredByCode ||
      '',
    ).trim();
    const referral = await resolveReferral(effectiveReferralCode);
    const discounts = [];
    let creatorBenefitApplied = false;

    if (planId === 'premium_monthly') {
      const creatorApplication = await approvedCreatorProgrammeApplication(uid);
      if (creatorApplication) {
        const creatorBenefitCoupon = await stripe.coupons.create({
          amount_off: 200,
          currency: 'gbp',
          duration: 'forever',
          name: 'UAG Approved Creator Premium Benefit',
          metadata: {
            uid,
            benefit: 'approved_creator_premium_at_essential_price',
            planId,
          },
        });
        discounts.push({ coupon: creatorBenefitCoupon.id });
        creatorBenefitApplied = true;
      }
    }

    if (
      plan.kind === 'core' &&
      !plan.offerId &&
      !creatorBenefitApplied &&
      referral &&
      referral.ownerUid !== uid &&
      referral.subscriberDiscountPercent > 0
    ) {
      const coupon = await stripe.coupons.create({
        percent_off: referral.subscriberDiscountPercent,
        duration: referral.subscriberDiscountDuration,
        name: referral.source === 'uag_community_referral'
          ? `UAG Refer a Raider ${referral.code}`
          : `UAG Creator Campaign ${referral.code}`,
        metadata: {
          referralCode: referral.code,
          ownerUid: referral.ownerUid,
          planId,
          source: referral.source,
        },
      });
      discounts.push({ coupon: coupon.id });
    }

    const metadata = {
      uid,
      planId,
      tier: plan.tier,
      billingPeriod: plan.billingPeriod,
      kind: plan.kind,
      offerId: plan.offerId || '',
      offerAudience: plan.offerAudience || '',
      passType: plan.passType || '',
      pricePence: String(plan.pricePence),
      referralCode: referral?.code || '',
      referralOwnerUid: referral && referral.ownerUid !== uid ? referral.ownerUid : '',
      referralSource: referral?.source || '',
      creatorBenefitApplied: creatorBenefitApplied ? 'true' : 'false',
    };

    const checkoutParams = {
      customer: customerId,
      mode: plan.kind === 'pass' ? 'payment' : 'subscription',
      line_items: [checkoutLineItem(plan, planId, priceId)],
      success_url: safeCheckoutReturnUrl(successUrl),
      cancel_url: safeCheckoutReturnUrl(cancelUrl),
      client_reference_id: uid,
      payment_method_types: plan.kind === 'pass' ? ['card'] : ['card', 'bacs_debit'],
      metadata,
    };
    if (discounts.length) checkoutParams.discounts = discounts;
    if (plan.kind !== 'pass') {
      checkoutParams.subscription_data = { metadata };
    }

    const session = await stripe.checkout.sessions.create(checkoutParams);

    await db.collection('monetisation_checkout_sessions').doc(session.id).set({
      id: session.id,
      uid,
      planId,
      kind: plan.kind,
      tier: plan.tier,
      billingPeriod: plan.billingPeriod,
      offerId: plan.offerId || null,
      offerAudience: plan.offerAudience || null,
      passType: plan.passType || null,
      pricePence: plan.pricePence,
      referralCode: referral?.code || null,
      referralOwnerUid: referral && referral.ownerUid !== uid ? referral.ownerUid : null,
      referralSource: referral?.source || null,
      creatorBenefitApplied,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: session.status || 'created',
    });

    res.status(200).json({ checkoutUrl: session.url, sessionId: session.id });
  } catch (error) {
    console.error('UAG checkout failed', error);
    const statusCode = Number(error?.statusCode || 500);
    res.status(statusCode >= 400 && statusCode < 600 ? statusCode : 500).json({
      error: statusCode >= 500
        ? 'Unable to start checkout right now. Please try again.'
        : (error.message || 'This offer is not available on this account.'),
    });
  }
});

exports.createUagCustomerPortalSession = onRequest({ secrets: [stripeSecretKey] }, async (req, res) => {
  try {
    if (setCheckoutCors(req, res)) return;
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
      return_url: safeCheckoutReturnUrl(req.body?.returnUrl),
    });
    res.status(200).json({ portalUrl: session.url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Unable to open subscription management right now. Please try again.' });
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
    if (event.type === 'charge.refunded') {
      await handleChargeReversal(event.data.object, 'refund');
    }
    if (event.type === 'charge.dispute.created') {
      const dispute = event.data.object;
      const charge = dispute.charge ? await stripe.charges.retrieve(dispute.charge) : null;
      if (charge) await handleChargeReversal(charge, 'chargeback');
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
  const planId = session.metadata?.planId;
  if (!planId) return;
  const plan = getPlan(planId);

  if (plan.kind === 'pass') {
    if (session.payment_status !== 'paid') return;
    await writePremiumPassEntitlement({ uid, plan, planId, session });
    return;
  }

  if (plan.kind === 'supporter') {
    await writeSupporterEntitlement({
      uid,
      plan,
      status: 'active',
      stripeCustomerId: session.customer || null,
      stripeSubscriptionId: session.subscription || null,
    });
    return;
  }

  await db.collection('users').doc(uid).set({
    monetisation: {
      tier: plan.tier,
      subscriptionStatus: 'active',
      billingPeriod: plan.billingPeriod,
      stripeCustomerId: session.customer || null,
      stripeSubscriptionId: session.subscription || null,
      referralCodeUsed: session.metadata?.referralCode || null,
      referredByUid: session.metadata?.referralOwnerUid || null,
      commercialOfferId: plan.offerId || null,
      founderRateActive: plan.offerAudience === 'founder',
      betaRateActive: plan.offerAudience === 'beta',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: plan.tier,
    subscriptionStatus: 'active',
  }, { merge: true });
}

async function handleSubscriptionUpdated(subscription) {
  const uid = subscription.metadata?.uid;
  if (!uid) return;
  const planId = subscription.metadata?.planId;
  if (!planId) return;
  const plan = getPlan(planId);
  const referralOwnerUid = normalizeString(subscription.metadata?.referralOwnerUid);
  const active = subscription.status === 'active' || subscription.status === 'trialing';

  const referralSource = normalizeString(subscription.metadata?.referralSource);
  if (referralOwnerUid && referralOwnerUid !== uid && plan.kind === 'core') {
    if (referralSource === 'uag_community_referral') {
      await syncCommunityPaidReferralSubscription({
        subscription,
        referredUid: uid,
        referrerUid: referralOwnerUid,
        plan,
        active,
      });
    } else {
      await upsertCreatorReferredSubscription({
        subscription,
        referredUid: uid,
        creatorUid: referralOwnerUid,
        plan,
        active,
      });
    }
  }

  if (plan.kind === 'supporter') {
    await writeSupporterEntitlement({
      uid,
      plan,
      status: subscription.status,
      stripeSubscriptionId: subscription.id,
      currentPeriodEnd: admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000),
      active,
    });
    return;
  }

  await db.collection('users').doc(uid).set({
    monetisation: {
      tier: active ? plan.tier : 'free',
      subscriptionStatus: subscription.status,
      billingPeriod: plan.billingPeriod,
      stripeSubscriptionId: subscription.id,
      currentPeriodEnd: admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000),
      commercialOfferId: plan.offerId || null,
      founderRateActive: active && plan.offerAudience === 'founder',
      betaRateActive: active && plan.offerAudience === 'beta',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: active ? plan.tier : 'free',
    subscriptionStatus: subscription.status,
  }, { merge: true });
}

async function handleSubscriptionDeleted(subscription) {
  const uid = subscription.metadata?.uid;
  if (!uid) return;
  const planId = subscription.metadata?.planId;
  if (!planId) return;
  const plan = getPlan(planId);
  const referralOwnerUid = normalizeString(subscription.metadata?.referralOwnerUid);

  const referralSource = normalizeString(subscription.metadata?.referralSource);
  if (referralOwnerUid && referralOwnerUid !== uid && plan.kind === 'core') {
    if (referralSource === 'uag_community_referral') {
      await syncCommunityPaidReferralSubscription({
        subscription,
        referredUid: uid,
        referrerUid: referralOwnerUid,
        plan,
        active: false,
      });
    } else {
      await beginCreatorSubscriptionGrace({
        subscriptionId: subscription.id,
        creatorUid: referralOwnerUid,
        referredUid: uid,
      });
    }
  }

  if (plan.kind === 'supporter') {
    await writeSupporterEntitlement({
      uid,
      plan,
      status: 'cancelled',
      stripeSubscriptionId: subscription.id,
      active: false,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  const voluntaryFounderCancellation =
    plan.offerAudience === 'founder' &&
    (subscription.cancellation_details?.reason === 'cancellation_requested' ||
      subscription.cancel_at_period_end === true);

  const userPatch = {
    monetisation: {
      tier: 'free',
      subscriptionStatus: 'cancelled',
      stripeSubscriptionId: subscription.id,
      founderRateActive: false,
      betaRateActive: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    tier: 'free',
    subscriptionStatus: 'cancelled',
  };

  if (voluntaryFounderCancellation) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    userPatch.founderRateForfeited = true;
    userPatch.founderRateForfeitedAt = now;
    userPatch.founderStatus = {
      rateForfeited: true,
      rateForfeitedAt: now,
    };
    userPatch.monetisation.founderRateForfeited = true;
    userPatch.monetisation.founderRateForfeitedAt = now;

    await db.collection('uag_commercial_recognition').doc(uid).set({
      founderRateForfeited: true,
      founderRateForfeitedAt: now,
      founderStatus: {
        rateForfeited: true,
        rateForfeitedAt: now,
      },
      updatedAt: now,
    }, { merge: true });
  }

  await db.collection('users').doc(uid).set(userPatch, { merge: true });
}

async function writePremiumPassEntitlement({ uid, plan, planId, session }) {
  const userRef = db.collection('users').doc(uid);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const userData = snapshot.data() || {};
    const existing = currentPremiumPass(userData);
    const nowMillis = Date.now();
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      nowMillis + Number(plan.passDurationHours || 0) * 60 * 60 * 1000,
    );
    const startedAt = admin.firestore.Timestamp.fromMillis(nowMillis);
    const passData = {
      active: true,
      type: plan.passType,
      planId,
      offerId: plan.offerId || null,
      startedAt,
      expiresAt,
      paidPence: plan.pricePence,
      usedDay24: truthy(existing.usedDay24) || plan.passType === 'day24',
      usedWeek7: truthy(existing.usedWeek7) || plan.passType === 'week7',
      stripeCheckoutSessionId: session.id,
      stripePaymentIntentId: normalizeString(session.payment_intent) || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    transaction.set(userRef, {
      monetisation: {
        premiumPass: passData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      premiumPass: passData,
    }, { merge: true });
    transaction.set(db.collection('monetisation_events').doc(session.id), {
      id: session.id,
      type: 'premium_pass_paid',
      uid,
      planId,
      tier: 'premium',
      billingPeriod: plan.billingPeriod,
      offerId: plan.offerId || null,
      passType: plan.passType,
      grossPence: plan.pricePence,
      stripeFeePence: estimateStripeFeePence(plan.pricePence),
      stripeCheckoutSessionId: session.id,
      stripePaymentIntentId: normalizeString(session.payment_intent) || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: false });
  });
}

async function writeSupporterEntitlement({
  uid,
  plan,
  status,
  stripeCustomerId = null,
  stripeSubscriptionId = null,
  currentPeriodEnd = null,
  active = true,
  cancelledAt = null,
}) {
  const supporterData = {
    active,
    foundingSupporter: true,
    status,
    monthlyPricePence: plan.pricePence,
    minimumMonthlyPricePence: plan.minimumPricePence,
    maximumMonthlyPricePence: plan.maximumPricePence,
    discountPercent: plan.futureDiscountPercent,
    stripeCustomerId,
    stripeSubscriptionId,
    currentPeriodEnd,
    cancelledAt,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (active) {
    supporterData.startedAt = admin.firestore.FieldValue.serverTimestamp();
  }
  await Promise.all([
    db.collection('supporter_entitlements').doc(uid).set({
      uid,
      ...supporterData,
    }, { merge: true }),
    db.collection('users').doc(uid).set({
      monetisation: {
        supporter: supporterData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      supporter: supporterData,
    }, { merge: true }),
  ]);
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
  const referralSource = subscription.metadata?.referralSource || '';
  const eligibleNetAmountPence = eligibleNetSubscriptionRevenuePence(
    invoice,
    grossPence,
    stripeFeePence,
  );

  if (referralOwnerUid && referralOwnerUid !== uid && plan.kind === 'core') {
    const active = subscription.status === 'active' || subscription.status === 'trialing';
    if (referralSource === 'uag_community_referral') {
      // Sync before calculating the rate so a first successful paid referral
      // earns the first 5% band even if invoice.paid arrives before the
      // subscription.updated webhook.
      await syncCommunityPaidReferralSubscription({
        subscription,
        referredUid: uid,
        referrerUid: referralOwnerUid,
        plan,
        active,
      });
    } else {
      await upsertCreatorReferredSubscription({
        subscription,
        referredUid: uid,
        creatorUid: referralOwnerUid,
        plan,
        active,
      });
    }
  }

  const creatorCommissionRatePercent = referralOwnerUid
    ? referralSource === 'uag_community_referral'
      ? await authoritativeCommunityCommissionRate(referralOwnerUid)
      : await authoritativeCreatorCommissionRate(referralOwnerUid)
    : 0;
  const referralCommissionPence = referralOwnerUid
    ? Math.round(eligibleNetAmountPence * (creatorCommissionRatePercent / 100))
    : 0;

  const charityPence = 0;
  const netPlatformProfitPence = Math.max(
    0,
    grossPence - stripeFeePence - referralCommissionPence,
  );

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
      referralSource: referralSource || null,
      stripeInvoiceId: invoice.id,
      stripeSubscriptionId: subscriptionId,
      stripePaymentIntentId: normalizeString(invoice.payment_intent) || null,
      eligibleNetAmountPence,
      creatorCommissionRatePercent,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (referralOwnerUid && referralCommissionPence > 0) {
      const walletRef = db.collection('referral_wallets').doc(referralOwnerUid);
      const isCommunity = referralSource === 'uag_community_referral';
      const commissionLedgerRef = isCommunity
        ? db
            .collection('uag_community_referral_commission_ledgers')
            .doc(referralOwnerUid)
            .collection('entries')
            .doc(invoice.id)
        : db
            .collection('uag_creator_commission_ledgers')
            .doc(referralOwnerUid)
            .collection('entries')
            .doc(invoice.id);

      transaction.set(walletRef, {
        uid: referralOwnerUid,
        pendingPence: admin.firestore.FieldValue.increment(referralCommissionPence),
        totalEarnedPence: admin.firestore.FieldValue.increment(referralCommissionPence),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(walletRef.collection('ledger').doc(invoice.id), {
        id: invoice.id,
        type: isCommunity
          ? 'community_commission_pending'
          : 'creator_commission_pending',
        source: referralSource || 'uag_creator_programme',
        amountPence: referralCommissionPence,
        referredUid: uid,
        planId,
        referralCode,
        commissionRatePercent: creatorCommissionRatePercent,
        releaseAfter: admin.firestore.Timestamp.fromMillis(
          Date.now() + 30 * 24 * 60 * 60 * 1000,
        ),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(commissionLedgerRef, {
        id: invoice.id,
        creatorUid: referralOwnerUid,
        ownerUid: referralOwnerUid,
        source: referralSource || 'uag_creator_programme',
        status: 'qualifying',
        amountPence: referralCommissionPence,
        currency: normalizeString(invoice.currency || 'gbp').toLowerCase() || 'gbp',
        referredAccountRef: stableAnonymizedUserRef(uid),
        subscriptionId,
        billingEventId: invoice.id,
        grossAmountPence: grossPence,
        discountPence: invoice.total_discount_amounts && invoice.total_discount_amounts.length
          ? invoice.total_discount_amounts.reduce((total, discount) => total + (discount.amount || 0), 0)
          : 0,
        netEligibleAmountPence: eligibleNetAmountPence,
        eligibleNetAmountPence,
        commissionRatePercent: creatorCommissionRatePercent,
        creatorCommissionRatePercent,
        commissionPence: referralCommissionPence,
        eventType: 'subscriptionStarted',
        lifecycleStatus: 'pendingValidation',
        reason: isCommunity
          ? 'Stripe invoice paid with Refer a Raider attribution.'
          : 'Stripe invoice paid with Creator Programme attribution.',
        stripePaymentIntentId: normalizeString(invoice.payment_intent) || null,
        qualificationDate: admin.firestore.Timestamp.fromMillis(
          Date.now() + 30 * 24 * 60 * 60 * 1000,
        ),
        payableAtIso: new Date(
          Date.now() + 30 * 24 * 60 * 60 * 1000,
        ).toISOString(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      if (!isCommunity) {
        const creatorAggregateRef = db
          .collection('uag_creator_dashboard_aggregates')
          .doc(referralOwnerUid);
        transaction.set(creatorAggregateRef, {
          uid: referralOwnerUid,
          paidConversions: admin.firestore.FieldValue.increment(1),
          pendingCommissionPence: admin.firestore.FieldValue.increment(referralCommissionPence),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }


  });
}


function communityBaseCommissionRate(activePaidReferrals) {
  const count = Number(activePaidReferrals || 0);
  if (count >= 100) return 15;
  if (count >= 50) return 12.5;
  if (count >= 25) return 10;
  if (count >= 5) return 7.5;
  if (count >= 1) return 5;
  return 0;
}

function premiumReferralBoost(userData) {
  const monetisation = userData?.monetisation || {};
  const tier = normalizeString(
    monetisation.tier || userData?.subscriptionTier || userData?.tier,
  ).toLowerCase();
  const status = normalizeString(
    monetisation.subscriptionStatus || userData?.subscriptionStatus,
  ).toLowerCase();
  return tier === 'premium' && ['active', 'trialing', 'trial', 'paid'].includes(status)
    ? 2.5
    : 0;
}

async function authoritativeCommunityCommissionRate(referrerUid) {
  if (!referrerUid) return 0;
  const [userSnap, referralStateSnap] = await Promise.all([
    db.collection('users').doc(referrerUid).get(),
    db.collection('uag_community_referral_paid_subscriptions')
      .where('referrerUid', '==', referrerUid)
      .get(),
  ]);
  const data = userSnap.data() || {};
  const activePaidReferrals = referralStateSnap.docs
    .filter((doc) => truthy(doc.data()?.active))
    .length;
  const base = communityBaseCommissionRate(activePaidReferrals);
  if (base <= 0) return 0;
  return base + premiumReferralBoost(data);
}

async function syncCommunityPaidReferralSubscription({
  subscription,
  referredUid,
  referrerUid,
  plan,
  active,
}) {
  if (!subscription?.id || !referredUid || !referrerUid || referrerUid === referredUid) {
    return;
  }
  const stateRef = db
    .collection('uag_community_referral_paid_subscriptions')
    .doc(subscription.id);
  const referrerRef = db.collection('users').doc(referrerUid);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(stateRef);
    const previousActive = existing.exists && truthy(existing.data()?.active);
    const delta = active === previousActive ? 0 : (active ? 1 : -1);

    transaction.set(stateRef, {
      subscriptionId: subscription.id,
      referrerUid,
      referredUid,
      tier: plan.tier,
      active,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: existing.exists
        ? existing.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp()
        : admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (delta !== 0) {
      transaction.set(referrerRef, {
        'communityReferral.activePaidReferrals':
          admin.firestore.FieldValue.increment(delta),
        'communityReferral.updatedAt':
          admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  });
}

function creatorBaseCommissionRate(points) {
  const value = Number(points || 0);
  if (value >= 60) return 20;
  if (value >= 40) return 17.5;
  if (value >= 25) return 15;
  if (value >= 15) return 12.5;
  if (value >= 8) return 10;
  if (value >= 1) return 7.5;
  return 0;
}

function communityCommissionUplift(qualifiedActiveUsers) {
  const users = Number(qualifiedActiveUsers || 0);
  if (users >= 250000) return 2.5;
  if (users >= 100000) return 2.0;
  if (users >= 50000) return 1.5;
  if (users >= 25000) return 1.0;
  if (users >= 10000) return 0.5;
  return 0;
}

async function authoritativeCreatorCommissionRate(creatorUid) {
  if (!creatorUid) return 0;
  const [creatorSnap, growthSnap] = await Promise.all([
    db.collection('uag_creator_dashboard_aggregates').doc(creatorUid).get(),
    db.collection('app_config').doc('community_growth').get(),
  ]);
  const creator = creatorSnap.data() || {};
  const growth = growthSnap.data() || {};
  const points = Number(creator.creatorPoints ?? creator.points ?? 0);
  const qualifiedActiveUsers = Number(growth.qualifiedActiveUsers || 0);
  const base = creatorBaseCommissionRate(points);
  if (base <= 0) return 0;
  return base + communityCommissionUplift(qualifiedActiveUsers);
}

function eligibleNetSubscriptionRevenuePence(invoice, grossPence, stripeFeePence) {
  // Stripe's current Invoice object exposes total_excluding_tax / total_taxes.
  // Keep the legacy total_tax_amounts fallback for older webhook fixtures.
  let netBeforeProcessingFee = Number(invoice.total_excluding_tax);
  if (!Number.isFinite(netBeforeProcessingFee)) {
    const currentTaxes = Array.isArray(invoice.total_taxes)
      ? invoice.total_taxes.reduce((sum, item) => sum + Number(item.amount || 0), 0)
      : 0;
    const legacyTaxes = Array.isArray(invoice.total_tax_amounts)
      ? invoice.total_tax_amounts.reduce((sum, item) => sum + Number(item.amount || 0), 0)
      : 0;
    netBeforeProcessingFee = Math.max(
      0,
      grossPence - Math.max(currentTaxes, legacyTaxes),
    );
  }
  return Math.max(0, Math.round(netBeforeProcessingFee) - stripeFeePence);
}

function rewardDurationDays(type) {
  if (type === 'premium30Days') return 30;
  if (type === 'premium365Days') return 365;
  return 7;
}

function activeTemporaryPremium(userData, nowMillis) {
  const grants = userData.creatorRewardEntitlements || {};
  return Object.values(grants).some((grant) => {
    if (!grant || String(grant.tier || '').toLowerCase() !== 'premium') return false;
    const expiry = grant.expiresAt?.toMillis ? grant.expiresAt.toMillis() : Date.parse(grant.expiresAt || '');
    return Number.isFinite(expiry) && expiry > nowMillis;
  });
}

const CREATOR_CANCELLATION_GRACE_DAYS = 30;
const COMMUNITY_REFERRAL_VALIDATION_DAYS = 30;

function creatorPointsForTier(tier) {
  const normalized = normalizeString(tier).toLowerCase();
  if (normalized === 'premium') return 1.5;
  if (normalized === 'essential') return 1;
  return 0;
}

async function recomputeCreatorCommercialAggregate(creatorUid) {
  if (!creatorUid) return;

  const [subscriptions, ledger] = await Promise.all([
    db.collection('uag_creator_referred_subscriptions')
      .where('creatorUid', '==', creatorUid)
      .get(),
    db.collection('uag_creator_commission_ledgers')
      .doc(creatorUid)
      .collection('entries')
      .get(),
  ]);

  const nowMillis = Date.now();
  let essentialActive = 0;
  let premiumActive = 0;
  let creatorPoints = 0;
  let pendingCommissionPence = 0;
  let approvedCommissionPence = 0;
  let paidCommissionPence = 0;
  let reversedCommissionPence = 0;
  let paidConversions = 0;
  let cancelledSubscriptions = 0;

  for (const doc of subscriptions.docs) {
    const row = doc.data() || {};
    const graceUntilMillis = row.graceUntil?.toMillis
      ? row.graceUntil.toMillis()
      : 0;
    const qualifiesForCreatorLevel =
      row.active === true ||
      (row.inCancellationGrace === true && graceUntilMillis > nowMillis);
    if (!qualifiesForCreatorLevel) continue;

    const tier = normalizeString(row.tier).toLowerCase();
    if (tier === 'essential') essentialActive += 1;
    if (tier === 'premium') premiumActive += 1;
    creatorPoints += creatorPointsForTier(tier);
  }

  for (const doc of ledger.docs) {
    const row = doc.data() || {};
    const amount = Number(row.commissionPence ?? row.amountPence ?? 0);
    const status = normalizeString(row.lifecycleStatus || row.status);

    if (status === 'pendingValidation' || status === 'qualifying') {
      pendingCommissionPence += amount;
    } else if (status === 'payable') {
      approvedCommissionPence += amount;
    } else if (status === 'paid') {
      paidCommissionPence += amount;
    } else if (status === 'reversed') {
      reversedCommissionPence += amount;
    }

    if (row.eventType === 'subscriptionStarted' && status !== 'reversed') {
      paidConversions += 1;
    }
    if (row.eventType === 'cancellation') {
      cancelledSubscriptions += 1;
    }
  }

  await db.collection('uag_creator_dashboard_aggregates').doc(creatorUid).set({
    uid: creatorUid,
    essentialActiveSubscribers: essentialActive,
    premiumActiveSubscribers: premiumActive,
    activeReferredSubscribers: essentialActive + premiumActive,
    creatorPoints,
    points: creatorPoints,
    pendingCommissionPence,
    approvedCommissionPence,
    paidCommissionPence,
    reversedCommissionPence,
    paidConversions,
    cancelledSubscriptions,
    lastReconciledAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function upsertCreatorReferredSubscription({
  subscription,
  referredUid,
  creatorUid,
  plan,
  active,
}) {
  const ref = db
    .collection('uag_creator_referred_subscriptions')
    .doc(subscription.id);

  await ref.set({
    subscriptionId: subscription.id,
    creatorUid,
    referredUid,
    tier: plan.tier,
    billingPeriod: plan.billingPeriod,
    points: creatorPointsForTier(plan.tier),
    status: subscription.status,
    active,
    inCancellationGrace: false,
    graceUntil: admin.firestore.FieldValue.delete(),
    currentPeriodEnd: subscription.current_period_end
      ? admin.firestore.Timestamp.fromMillis(subscription.current_period_end * 1000)
      : null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await recomputeCreatorCommercialAggregate(creatorUid);
}

async function beginCreatorSubscriptionGrace({
  subscriptionId,
  creatorUid,
  referredUid,
}) {
  const ref = db
    .collection('uag_creator_referred_subscriptions')
    .doc(subscriptionId);
  const graceUntil = admin.firestore.Timestamp.fromMillis(
    Date.now() +
      CREATOR_CANCELLATION_GRACE_DAYS * 24 * 60 * 60 * 1000,
  );

  await ref.set({
    subscriptionId,
    creatorUid,
    referredUid,
    active: false,
    status: 'cancelled',
    inCancellationGrace: true,
    cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    graceUntil,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const cancellationId = `cancellation_${subscriptionId}`;
  await db
    .collection('uag_creator_commission_ledgers')
    .doc(creatorUid)
    .collection('entries')
    .doc(cancellationId)
    .set({
      id: cancellationId,
      creatorUid,
      subscriptionId,
      eventType: 'cancellation',
      status: 'informational',
      lifecycleStatus: 'informational',
      commissionPence: 0,
      amountPence: 0,
      referredAccountRef: stableAnonymizedUserRef(referredUid),
      graceUntil,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

  await recomputeCreatorCommercialAggregate(creatorUid);
}

async function resolveInvoiceIdForCharge(charge) {
  // Older Stripe API versions expose charge.invoice directly. Newer Charge
  // shapes reliably expose payment_intent, so support both.
  const directInvoice = normalizeString(charge.invoice);
  if (directInvoice) return directInvoice;

  const paymentIntentId = normalizeString(charge.payment_intent);
  if (!paymentIntentId) return '';

  const match = await db
    .collection('monetisation_events')
    .where('stripePaymentIntentId', '==', paymentIntentId)
    .limit(1)
    .get();

  return match.empty ? '' : match.docs[0].id;
}

function referralMilestoneReward(threshold, referrerUid) {
  if (threshold === 1) {
    return {
      rewardId: `community_referral_${referrerUid}_1`,
      type: 'premium7Days',
    };
  }
  if (threshold === 3) {
    return {
      rewardId: `community_referral_${referrerUid}_3`,
      type: 'premium30Days',
    };
  }
  return null;
}

async function bankReferralRewardAuthoritatively({
  uid,
  rewardId,
  type,
  sourceRef,
}) {
  const lockerRef = db.collection('uag_referral_reward_lockers').doc(uid);
  const rewardRef = lockerRef.collection('rewards').doc(rewardId);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(rewardRef);
    if (existing.exists) return;

    transaction.set(lockerRef, {
      uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(rewardRef, {
      id: rewardId,
      uid,
      type,
      status: 'banked',
      source: 'community_referral',
      sourceRef,
      earnedAt: admin.firestore.FieldValue.serverTimestamp(),
      earnedAtIso: new Date().toISOString(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function validateCommunityReferralAuthoritatively({
  queueRef,
  referredUid,
}) {
  const attributionRef = db
    .collection('users')
    .doc(referredUid)
    .collection('monetisation_usage')
    .doc('community_referral_attribution');

  const attributionSnap = await attributionRef.get();
  if (!attributionSnap.exists) {
    await queueRef.set({
      status: 'invalid',
      reason: 'missing_attribution',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return;
  }

  const attribution = attributionSnap.data() || {};
  if (attribution.status !== 'pending_validation') {
    await queueRef.set({
      status: attribution.status === 'validated' ? 'completed' : 'invalid',
      reason: `attribution_${normalizeString(attribution.status) || 'unknown'}`,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return;
  }

  const referrerUid = normalizeString(attribution.referrerUid);
  if (!referrerUid || referrerUid === referredUid) {
    await queueRef.set({
      status: 'invalid',
      reason: 'invalid_referrer',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return;
  }

  try {
    const authUser = await admin.auth().getUser(referredUid);
    if (authUser.disabled) {
      await queueRef.set({
        status: 'invalid',
        reason: 'referred_account_disabled',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }
  } catch (_) {
    await queueRef.set({
      status: 'invalid',
      reason: 'referred_account_missing',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return;
  }

  const referrerRef = db.collection('users').doc(referrerUid);
  let newlyAwarded = [];

  await db.runTransaction(async (transaction) => {
    const [freshAttribution, referrerSnap, freshQueue] = await Promise.all([
      transaction.get(attributionRef),
      transaction.get(referrerRef),
      transaction.get(queueRef),
    ]);

    if (
      !freshAttribution.exists ||
      freshAttribution.data()?.status !== 'pending_validation'
    ) {
      return;
    }
    if (!referrerSnap.exists) return;
    if (freshQueue.exists && freshQueue.data()?.status === 'completed') return;

    const referral = referrerSnap.data()?.communityReferral || {};
    const previous = Number(referral.validatedReferrals || 0);
    const next = previous + 1;
    const alreadyAwarded = Array.isArray(referral.awardedMilestones)
      ? referral.awardedMilestones.map(Number)
      : [];

    newlyAwarded = [1, 3, 5].filter(
      (threshold) =>
        previous < threshold &&
        next >= threshold &&
        !alreadyAwarded.includes(threshold),
    );

    const awardedMilestones = Array.from(
      new Set([...alreadyAwarded, ...newlyAwarded]),
    ).sort((a, b) => a - b);

    transaction.set(attributionRef, {
      status: 'validated',
      validatedAt: admin.firestore.FieldValue.serverTimestamp(),
      validatedBy: 'server_retention_policy',
      validationReason: '30-day retained account validation',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(referrerRef, {
      'communityReferral.validatedReferrals': next,
      'communityReferral.pendingReferrals': Math.max(
        0,
        Number(referral.pendingReferrals || 0) - 1,
      ),
      'communityReferral.awardedMilestones': awardedMilestones,
      'communityReferral.creatorFastTrackUnlocked':
        awardedMilestones.includes(5),
      'communityReferral.updatedAt':
        admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(queueRef, {
      status: 'completed',
      validatedAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  for (const threshold of newlyAwarded) {
    const reward = referralMilestoneReward(threshold, referrerUid);
    if (!reward) continue;

    await bankReferralRewardAuthoritatively({
      uid: referrerUid,
      rewardId: reward.rewardId,
      type: reward.type,
      sourceRef: `validated_referral:${referredUid}:milestone:${threshold}`,
    });
  }
}

async function handleChargeReversal(charge, reversalType) {
  const invoiceId = await resolveInvoiceIdForCharge(charge);
  if (!invoiceId) return;

  const eventRef = db.collection('monetisation_events').doc(invoiceId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) return;
  const event = eventSnap.data() || {};
  const creatorUid = normalizeString(event.referralOwnerUid);
  if (!creatorUid) return;
  const referralSource = normalizeString(event.referralSource);
  const ledgerCollection = referralSource === 'uag_community_referral'
    ? 'uag_community_referral_commission_ledgers'
    : 'uag_creator_commission_ledgers';

  const ledgerRef = db
    .collection(ledgerCollection)
    .doc(creatorUid)
    .collection('entries')
    .doc(invoiceId);

  let reversedAmountPence = 0;
  let reversedFromStatus = '';

  await db.runTransaction(async (transaction) => {
    const ledger = await transaction.get(ledgerRef);
    if (!ledger.exists) return;
    const data = ledger.data() || {};
    if (data.lifecycleStatus === 'reversed' || data.status === 'reversed') return;

    reversedAmountPence = Number(
      data.commissionPence ?? data.amountPence ?? 0,
    );
    reversedFromStatus =
      data.lifecycleStatus || data.status || 'unknown';

    transaction.set(ledgerRef, {
      status: 'reversed',
      lifecycleStatus: 'reversed',
      reversedFromStatus,
      reversalType,
      reversalReason: `Stripe ${reversalType}`,
      reversedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    transaction.set(eventRef, {
      reversalType,
      reversedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  if (reversedAmountPence > 0) {
    const walletPatch = {
      reversedPence:
        admin.firestore.FieldValue.increment(reversedAmountPence),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (
      reversedFromStatus === 'pendingValidation' ||
      reversedFromStatus === 'qualifying'
    ) {
      walletPatch.pendingPence =
        admin.firestore.FieldValue.increment(-reversedAmountPence);
    } else if (reversedFromStatus === 'payable') {
      walletPatch.payablePence =
        admin.firestore.FieldValue.increment(-reversedAmountPence);
    }

    await db.collection('referral_wallets').doc(creatorUid).set(
      walletPatch,
      { merge: true },
    );
  }

  if (referralSource !== 'uag_community_referral') {
    await recomputeCreatorCommercialAggregate(creatorUid);
  }
}

exports.queueCommunityReferralValidation = onDocumentCreated(
  'users/{referredUid}/monetisation_usage/community_referral_attribution',
  async (event) => {
    const referredUid = event.params.referredUid;
    const data = event.data?.data() || {};
    const referrerUid = normalizeString(data.referrerUid);

    if (!referredUid || !referrerUid || referrerUid === referredUid) return;
    if (data.status !== 'pending_validation') return;

    const capturedAtMillis = data.capturedAt?.toMillis
      ? data.capturedAt.toMillis()
      : Date.now();
    const dueAt = admin.firestore.Timestamp.fromMillis(
      capturedAtMillis +
        COMMUNITY_REFERRAL_VALIDATION_DAYS * 24 * 60 * 60 * 1000,
    );

    await db
      .collection('uag_community_referral_validation_queue')
      .doc(referredUid)
      .set({
        referredUid,
        referrerUid,
        status: 'pending',
        dueAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
  },
);

exports.activateReferralRewardAuthoritatively = onDocumentCreated(
  'uag_referral_reward_activation_requests/{requestId}',
  async (event) => {
    const request = event.data?.data() || {};
    const requestRef = event.data?.ref;
    if (!requestRef) return;

    const uid = normalizeString(request.uid);
    const rewardId = normalizeString(request.rewardId);
    if (!uid || !rewardId || request.status !== 'pending') {
      await requestRef.set({
        status: 'rejected',
        publicReason: 'Invalid reward activation request.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }

    const lockerRef = db.collection('uag_referral_reward_lockers').doc(uid);
    const rewardRef = lockerRef.collection('rewards').doc(rewardId);
    const userRef = db.collection('users').doc(uid);

    await db.runTransaction(async (transaction) => {
      const [stateSnap, rewardSnap, userSnap] = await Promise.all([
        transaction.get(lockerRef),
        transaction.get(rewardRef),
        transaction.get(userRef),
      ]);

      if (!rewardSnap.exists) {
        transaction.set(requestRef, {
          status: 'rejected',
          publicReason: 'Reward was not found.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
      }

      const reward = rewardSnap.data() || {};
      const user = userSnap.data() || {};
      const state = stateSnap.data() || {};
      const now = Date.now();

      if (reward.status !== 'banked') {
        transaction.set(requestRef, {
          status: reward.status === 'active' ? 'completed' : 'rejected',
          publicReason: reward.status === 'active'
            ? 'Reward is already active.'
            : 'Reward is not available for activation.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
      }

      const stateExpiry = state.activeUntil?.toMillis
        ? state.activeUntil.toMillis()
        : 0;
      if (state.activeRewardId && stateExpiry > now) {
        transaction.set(requestRef, {
          status: 'rejected',
          publicReason: 'Another banked reward is already active.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
      }

      const paidTier = String(
        user.monetisation?.tier || user.subscriptionTier || user.tier || 'free',
      ).toLowerCase();
      if (paidTier === 'premium' || activeTemporaryPremium(user, now)) {
        transaction.set(requestRef, {
          status: 'rejected',
          publicReason: 'Premium is already active. Keep this reward banked for later.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return;
      }

      const days = rewardDurationDays(reward.type);
      const expiresAt = admin.firestore.Timestamp.fromMillis(
        now + days * 24 * 60 * 60 * 1000,
      );
      const grantId = `referral_locker_${rewardId}`;

      transaction.set(rewardRef, {
        status: 'active',
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      transaction.set(lockerRef, {
        uid,
        activeRewardId: rewardId,
        activeUntil: expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      transaction.update(userRef, {
        [`creatorRewardEntitlements.${grantId}`]: {
          grantId,
          tier: 'premium',
          startedAt: admin.firestore.Timestamp.fromMillis(now),
          expiresAt,
          source: 'community_referral_locker',
          sourceRef: rewardId,
          rewardType: reward.type || 'premium7Days',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });

      transaction.set(requestRef, {
        status: 'completed',
        grantId,
        expiresAt,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  },
);

exports.releaseCreatorCommissionDaily = onSchedule('every day 03:15', async () => {
  const now = admin.firestore.Timestamp.now();

  // A single range filter avoids the known composite-index dependency.
  // Lifecycle state is rechecked transactionally before any release.
  const candidates = await db
    .collectionGroup('entries')
    .where('qualificationDate', '<=', now)
    .limit(500)
    .get();

  const creatorsToReconcile = new Set();

  for (const doc of candidates.docs) {
    let releasedAmountPence = 0;
    let creatorUid = '';

    await db.runTransaction(async (transaction) => {
      const fresh = await transaction.get(doc.ref);
      if (!fresh.exists) return;
      const data = fresh.data() || {};
      if (data.lifecycleStatus !== 'pendingValidation') return;

      releasedAmountPence = Number(
        data.commissionPence ?? data.amountPence ?? 0,
      );
      creatorUid = normalizeString(data.creatorUid);

      transaction.set(doc.ref, {
        status: 'payable',
        lifecycleStatus: 'payable',
        qualifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    if (creatorUid && releasedAmountPence > 0) {
      const source = normalizeString(doc.data()?.source);
      if (source !== 'uag_community_referral') creatorsToReconcile.add(creatorUid);
      await db.collection('referral_wallets').doc(creatorUid).set({
        pendingPence:
          admin.firestore.FieldValue.increment(-releasedAmountPence),
        payablePence:
          admin.firestore.FieldValue.increment(releasedAmountPence),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }

  for (const creatorUid of creatorsToReconcile) {
    await recomputeCreatorCommercialAggregate(creatorUid);
  }
});

exports.expireCreatorCancellationGraceDaily = onSchedule(
  'every day 03:45',
  async () => {
    const now = admin.firestore.Timestamp.now();
    const expired = await db
      .collection('uag_creator_referred_subscriptions')
      .where('graceUntil', '<=', now)
      .limit(500)
      .get();

    const creators = new Set();

    for (const doc of expired.docs) {
      const row = doc.data() || {};
      if (row.inCancellationGrace !== true) continue;

      const creatorUid = normalizeString(row.creatorUid);
      await doc.ref.set({
        inCancellationGrace: false,
        graceExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      if (creatorUid) creators.add(creatorUid);
    }

    for (const creatorUid of creators) {
      await recomputeCreatorCommercialAggregate(creatorUid);
    }
  },
);

exports.validateCommunityReferralsDaily = onSchedule(
  'every day 04:15',
  async () => {
    const now = admin.firestore.Timestamp.now();
    const due = await db
      .collection('uag_community_referral_validation_queue')
      .where('dueAt', '<=', now)
      .limit(500)
      .get();

    for (const queueDoc of due.docs) {
      const queue = queueDoc.data() || {};
      if (queue.status !== 'pending') continue;
      const referredUid = normalizeString(queue.referredUid || queueDoc.id);
      if (!referredUid) continue;

      await validateCommunityReferralAuthoritatively({
        queueRef: queueDoc.ref,
        referredUid,
      });
    }
  },
);

exports.expireReferralRewardsHourly = onSchedule('every 60 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const lockers = await db
    .collection('uag_referral_reward_lockers')
    .where('activeUntil', '<=', now)
    .limit(250)
    .get();

  for (const locker of lockers.docs) {
    const state = locker.data() || {};
    const rewardId = normalizeString(state.activeRewardId);
    if (!rewardId) continue;
    const rewardRef = locker.ref.collection('rewards').doc(rewardId);
    await db.runTransaction(async (transaction) => {
      const freshLocker = await transaction.get(locker.ref);
      const freshReward = await transaction.get(rewardRef);
      if (!freshLocker.exists || !freshReward.exists) return;
      const expiry = freshLocker.data()?.activeUntil;
      if (!expiry || expiry.toMillis() > Date.now()) return;
      transaction.set(rewardRef, {
        status: 'consumed',
        consumedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(locker.ref, {
        activeRewardId: admin.firestore.FieldValue.delete(),
        activeUntil: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  }
});
function normalizeString(value) {
  return String(value || '').trim();
}

function stableAnonymizedUserRef(uid) {
  const normalized = normalizeString(uid);
  if (!normalized) return 'user_unknown';
  return `user_${normalized.slice(-6)}`;
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
    case 'trade_offer':
    case 'trade_accepted':
    case 'trade_rejected':
    case 'trade_reminder':
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
    case 'matchmaking_session':
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
    case 'item_relevance_warning':
    case 'founding_supporter_event':
      return 'operationsAndRewards';
    case 'blueprint_report_confirmed':
    case 'community_intel_confirmation':
    case 'community_intel_dispute':
      return 'blueprintIntel';
    case 'contract_offered':
    case 'contract_accepted':
    case 'contract_evidence_submitted':
    case 'contract_reward_ready':
    case 'contract_dispute':
    case 'conduct_report_response':
    case 'conduct_report_outcome':
      return 'contractsAndReports';
    case 'terms_privacy_update':
    case 'age_verification_required':
      return 'legalAndPolicy';
    case 'creator_referral':
    case 'creator_paid_conversion':
    case 'creator_commission_changed':
    case 'subscription_event':
    case 'payment_failure':
      return 'announcements';
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

function parseDateOnly(value) {
  const parsed = Date.parse(normalizeString(value));
  if (Number.isNaN(parsed)) return null;
  const date = new Date(parsed);
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function evaluateAgeVerification(dateOfBirthIso, now = new Date()) {
  const birthDate = parseDateOnly(dateOfBirthIso);
  if (!birthDate) {
    return {
      status: 'rejected',
      verifiedOver18: false,
      ageYears: 0,
      decisionReason: 'Date of birth is missing or invalid.',
    };
  }
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  if (birthDate > today) {
    return {
      status: 'rejected',
      verifiedOver18: false,
      ageYears: 0,
      decisionReason: 'Date of birth cannot be in the future.',
    };
  }
  let ageYears = today.getUTCFullYear() - birthDate.getUTCFullYear();
  const birthdayThisYear = new Date(Date.UTC(
    today.getUTCFullYear(),
    birthDate.getUTCMonth(),
    birthDate.getUTCDate()
  ));
  if (birthdayThisYear > today) ageYears -= 1;
  if (ageYears >= 18) {
    return {
      status: 'accepted',
      verifiedOver18: true,
      ageYears,
      decisionReason: 'Account holder meets the 18+ service requirement.',
    };
  }
  return {
    status: 'rejected',
    verifiedOver18: false,
    ageYears,
    decisionReason: 'UAG ARC Raiders Hub is an 18+ service.',
  };
}

function messagingBlockId(blockerUid, blockedUid) {
  return `${normalizeString(blockerUid)}_${normalizeString(blockedUid)}`;
}

async function userHasVerifiedAge(uid) {
  const userSnap = await db.collection('users').doc(uid).get();
  const data = userSnap.data() || {};
  return data.ageVerification?.verifiedOver18 === true;
}

async function usersBlockedBetween(leftUid, rightUid) {
  const [leftBlock, rightBlock] = await Promise.all([
    db.collection('uag_user_blocks').doc(messagingBlockId(leftUid, rightUid)).get(),
    db.collection('uag_user_blocks').doc(messagingBlockId(rightUid, leftUid)).get(),
  ]);
  return leftBlock.exists || rightBlock.exists;
}

function deterministicModerationDecision(body) {
  const normalized = normalizeString(body).toLowerCase();
  const rules = [];
  let score = 0;
  const add = (rule, value) => {
    if (!rules.includes(rule)) rules.push(rule);
    score += value;
  };
  if (!normalized) add('empty_message', 0.45);
  if (/\b(kill yourself|kys|i will kill|death threat)\b/.test(normalized)) {
    add('threat_or_self_harm_abuse', 0.95);
  }
  if (/\b(child|minor|underage)\b.*\b(sex|nude|meet)\b/.test(normalized)) {
    add('sexual_or_grooming_risk', 1);
  }
  if (/\b(password|2fa|verification code|login code)\b/.test(normalized)) {
    add('credential_phishing', 0.65);
  }
  if (/\b(paypal|bank transfer|crypto|wallet address|cashapp)\b/.test(normalized)) {
    add('off_platform_payment_request', 0.3);
  }
  if (/\b\d{3,}[- .]?\d{3,}[- .]?\d{3,}\b/.test(normalized)) {
    add('phone_or_private_number', 0.25);
  }
  if (/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}/.test(normalized)) {
    add('email_address', 0.25);
  }
  if (/https?:\/\/|www\./.test(normalized)) add('external_url', 0.15);
  ['bit.ly', 'tinyurl.com', 't.me', 'discord.gg'].forEach((domain) => {
    if (normalized.includes(domain)) add(`blocked_domain:${domain}`, 0.35);
  });

  const boundedScore = Math.max(0, Math.min(1, score));
  const severe = rules.includes('threat_or_self_harm_abuse') ||
    rules.includes('sexual_or_grooming_risk');
  if (severe && boundedScore >= 0.95) {
    return {
      state: 'blocked',
      action: 'blockAndEscalate',
      score: boundedScore,
      triggeredRules: rules,
      reason: 'Severe automated safety rule triggered.',
    };
  }
  if (boundedScore >= 0.7) {
    return {
      state: 'quarantined',
      action: 'quarantine',
      score: boundedScore,
      triggeredRules: rules,
      reason: 'Message withheld for moderation review.',
    };
  }
  if (boundedScore >= 0.35) {
    return {
      state: 'warned',
      action: 'warnAndAllowEdit',
      score: boundedScore,
      triggeredRules: rules,
      reason: 'Message should be edited or confirmed before delivery.',
    };
  }
  return {
    state: 'allowed',
    action: 'deliver',
    score: boundedScore,
    triggeredRules: rules,
    reason: 'No blocking safety rule triggered.',
  };
}

function moderationProviderConfig() {
  const enabled = normalizeString(process.env.UAG_MODERATION_PROVIDER_ENABLED).toLowerCase() === 'true';
  const provider = normalizeString(process.env.UAG_MODERATION_PROVIDER || 'google_natural_language');
  const projectId = normalizeString(
    process.env.UAG_MODERATION_PROJECT_ID ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT
  );
  const timeoutMs = Math.max(
    1000,
    Math.min(15000, Number.parseInt(process.env.UAG_MODERATION_TIMEOUT_MS || '5000', 10) || 5000)
  );
  return {
    enabled,
    provider,
    projectId,
    region: normalizeString(process.env.UAG_MODERATION_REGION || 'global'),
    timeoutMs,
  };
}

function ocrProviderConfig() {
  const enabled = normalizeString(process.env.UAG_OCR_PROVIDER_ENABLED).toLowerCase() === 'true';
  const provider = normalizeString(process.env.UAG_OCR_PROVIDER || 'google_cloud_vision');
  const projectId = normalizeString(
    process.env.UAG_OCR_PROJECT_ID ||
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT
  );
  return {
    enabled,
    provider,
    projectId,
    region: normalizeString(process.env.UAG_OCR_REGION || 'global'),
  };
}

function disabledProviderResult(config) {
  return {
    configured: false,
    provider: config.provider,
    state: 'disabled',
    score: 0,
    categories: [],
    triggeredRules: [],
    reason: 'External moderation provider is disabled. Deterministic checks remain active.',
    auditMetadata: {
      provider: config.provider,
      projectIdConfigured: Boolean(config.projectId),
      region: config.region,
    },
  };
}

async function fetchGoogleAccessToken(timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(
      'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
      {
        headers: { 'Metadata-Flavor': 'Google' },
        signal: controller.signal,
      }
    );
    if (!response.ok) {
      throw new Error(`metadata_token_${response.status}`);
    }
    const json = await response.json();
    return normalizeString(json.access_token);
  } finally {
    clearTimeout(timer);
  }
}

function mapNaturalLanguageCategory(category) {
  const name = normalizeString(category.name);
  const confidence = Math.max(0, Math.min(1, Number(category.confidence || 0)));
  const key = name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  return {
    name,
    key,
    confidence,
    rule: `provider_google_natural_language:${key || 'unknown'}`,
  };
}

function providerDecisionFromCategories(categories) {
  const meaningful = categories.filter((category) => category.confidence >= 0.55);
  const score = categories.reduce((best, category) => Math.max(best, category.confidence), 0);
  const sensitive = meaningful.filter((category) => [
    'toxic',
    'derogatory',
    'violent',
    'sexual',
    'insult',
    'profanity',
    'death_harm_tragedy',
    'firearms_weapons',
    'public_safety',
    'illicit_drugs',
    'war_conflict',
  ].includes(category.key));

  if (sensitive.some((category) => category.confidence >= 0.85)) {
    return {
      state: 'quarantined',
      action: 'quarantine',
      score,
      triggeredRules: sensitive.map((category) => category.rule),
      reason: 'External moderation provider flagged high-confidence safety categories.',
    };
  }
  if (sensitive.length > 0) {
    return {
      state: 'warning_required',
      action: 'warnAndAllowEdit',
      score,
      triggeredRules: sensitive.map((category) => category.rule),
      reason: 'External moderation provider flagged content that should be reviewed before delivery.',
    };
  }
  return {
    state: 'allowed',
    action: 'deliver',
    score,
    triggeredRules: [],
    reason: 'External moderation provider did not flag configured safety categories.',
  };
}

async function runExternalModerationProvider(body) {
  const config = moderationProviderConfig();
  if (!config.enabled) return disabledProviderResult(config);
  if (config.provider !== 'google_natural_language') {
    return {
      configured: true,
      provider: config.provider,
      state: 'provider_unavailable',
      score: 0,
      categories: [],
      triggeredRules: ['provider_unknown'],
      reason: `Unsupported moderation provider configured: ${config.provider}.`,
      auditMetadata: { provider: config.provider, region: config.region },
    };
  }
  try {
    const token = await fetchGoogleAccessToken(config.timeoutMs);
    if (!token) throw new Error('metadata_token_empty');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), config.timeoutMs);
    try {
      const response = await fetch('https://language.googleapis.com/v1/documents:moderateText', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: JSON.stringify({
          document: {
            type: 'PLAIN_TEXT',
            content: body,
          },
        }),
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new Error(`language_moderate_text_${response.status}`);
      }
      const json = await response.json();
      const categories = Array.isArray(json.moderationCategories)
        ? json.moderationCategories.map(mapNaturalLanguageCategory)
        : [];
      const decision = providerDecisionFromCategories(categories);
      return {
        configured: true,
        provider: 'google_natural_language',
        categories,
        ...decision,
        auditMetadata: {
          provider: 'google_natural_language',
          projectId: config.projectId,
          region: config.region,
          categoryCount: categories.length,
        },
      };
    } finally {
      clearTimeout(timer);
    }
  } catch (error) {
    return {
      configured: true,
      provider: 'google_natural_language',
      state: 'provider_unavailable',
      action: 'humanReview',
      score: 0,
      categories: [],
      triggeredRules: ['provider_unavailable'],
      reason: `External moderation provider unavailable: ${error.message || error}`,
      auditMetadata: {
        provider: 'google_natural_language',
        projectId: config.projectId,
        region: config.region,
      },
    };
  }
}

async function writeModerationQueue({ id, data, decision, reason }) {
  await db.collection('uag_moderation_queue').doc(id).set({
    id,
    source: 'uag_message_outbox',
    sourceId: id,
    senderUid: normalizeString(data.senderUid),
    recipientUid: normalizeString(data.recipientUid),
    conversationId: normalizeString(data.conversationId),
    contextType: normalizeString(data.contextType || 'direct_message'),
    contextId: normalizeString(data.contextId),
    body: normalizeString(data.body),
    state: decision.state,
    action: decision.action,
    score: decision.score,
    triggeredRules: decision.triggeredRules,
    providerConfigured: decision.providerConfigured === true,
    provider: decision.provider || 'deterministic_rules',
    providerCategories: decision.providerCategories || [],
    providerAudit: decision.providerAudit || {},
    reason: reason || decision.reason,
    illegalContentPriority: decision.triggeredRules.some((rule) => rule.includes('grooming')),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
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

exports.uagReleaseHealthCheck = onRequest(async (req, res) => {
  try {
    const moderation = moderationProviderConfig();
    const ocr = ocrProviderConfig();
    const planChecks = Object.entries(PLAN_CONFIG).map(([id, plan]) => ({
      id,
      kind: plan.kind,
      tier: plan.tier,
      priceEnv: plan.stripePriceEnv,
      priceConfigured: Boolean(process.env[plan.stripePriceEnv]),
    }));
    res.status(200).json({
      ok: true,
      generatedAt: new Date().toISOString(),
      firebaseProject: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '',
      moderation: {
        enabled: moderation.enabled,
        provider: moderation.provider,
        projectConfigured: Boolean(moderation.projectId),
        region: moderation.region,
        timeoutMs: moderation.timeoutMs,
      },
      ocr: {
        enabled: ocr.enabled,
        provider: ocr.provider,
        projectConfigured: Boolean(ocr.projectId),
        region: ocr.region,
      },
      stripe: {
        secretBound: Boolean(process.env.STRIPE_SECRET_KEY),
        webhookSecretBound: Boolean(process.env.STRIPE_WEBHOOK_SECRET),
        planChecks,
      },
      notifications: {
        fcmAdminSdkAvailable: Boolean(admin.messaging),
      },
      storage: {
        rulesTargetRequired: true,
      },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      error: error.message || 'Release health check failed.',
    });
  }
});

exports.processUagAgeVerificationRequest = onDocumentCreated(
  'uag_age_verification_requests/{requestId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const requestId = event.params.requestId;
    const data = snap.data() || {};
    const uid = normalizeString(data.uid);
    if (!uid || normalizeString(data.id || requestId) !== requestId) {
      await snap.ref.set({
        status: 'rejected',
        verifiedOver18: false,
        decisionReason: 'Age verification request is malformed.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      return;
    }

    const decision = evaluateAgeVerification(data.dateOfBirthIso);
    await db.runTransaction(async (transaction) => {
      transaction.set(snap.ref, {
        status: decision.status,
        verifiedOver18: decision.verifiedOver18,
        ageYearsAtDecision: decision.ageYears,
        decisionReason: decision.decisionReason,
        provider: 'server_dob_gate',
        decidedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(db.collection('users').doc(uid), {
        ageVerification: {
          status: decision.status,
          verifiedOver18: decision.verifiedOver18,
          verificationRequestId: requestId,
          provider: 'server_dob_gate',
          decisionReason: decision.decisionReason,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });
    });
  }
);

exports.processUagMessageOutbox = onDocumentCreated(
  'uag_message_outbox/{messageId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const messageId = event.params.messageId;
    const data = snap.data() || {};
    const senderUid = normalizeString(data.senderUid);
    const recipientUid = normalizeString(data.recipientUid);
    const body = normalizeString(data.body);

    async function reject(status, reason, decision = null) {
      if (decision) {
        await writeModerationQueue({ id: messageId, data, decision, reason });
      }
      await snap.ref.set({
        status,
        deliveryBlocked: true,
        reason,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    if (!senderUid || !recipientUid || senderUid === recipientUid || !body) {
      await reject('blocked_invalid_request', 'Message request is invalid.');
      return;
    }
    if (!(await userHasVerifiedAge(senderUid))) {
      await reject(
        'blocked_age_verification_required',
        'Sender must complete 18+ verification before messaging.'
      );
      return;
    }
    if (!(await userHasVerifiedAge(recipientUid))) {
      await reject(
        'blocked_recipient_age_unverified',
        'Recipient has not completed 18+ verification.'
      );
      return;
    }
    if (await usersBlockedBetween(senderUid, recipientUid)) {
      await reject('blocked_user_block', 'Messaging is blocked between these users.');
      return;
    }

    const decision = deterministicModerationDecision(body);
    if (decision.action === 'warnAndAllowEdit') {
      await reject('warning_required', decision.reason, decision);
      return;
    }
    if (decision.action !== 'deliver') {
      await reject(decision.state, decision.reason, decision);
      return;
    }

    const providerResult = await runExternalModerationProvider(body);
    const providerDecision = {
      state: providerResult.state,
      action: providerResult.action || 'deliver',
      score: providerResult.score || 0,
      triggeredRules: providerResult.triggeredRules || [],
      reason: providerResult.reason,
      providerConfigured: providerResult.configured === true,
      provider: providerResult.provider,
      providerCategories: providerResult.categories || [],
      providerAudit: providerResult.auditMetadata || {},
    };
    if (providerDecision.state === 'provider_unavailable') {
      await reject('provider_unavailable', providerDecision.reason, providerDecision);
      return;
    }
    if (providerDecision.action === 'warnAndAllowEdit') {
      await reject('warning_required', providerDecision.reason, providerDecision);
      return;
    }
    if (providerDecision.action !== 'deliver') {
      await reject(providerDecision.state, providerDecision.reason, providerDecision);
      return;
    }

    await db.runTransaction(async (transaction) => {
      const current = await transaction.get(snap.ref);
      const currentData = current.data() || {};
      if (normalizeString(currentData.status) !== 'queued') return;
      const messageRef = db.collection('uag_messages').doc(messageId);
      transaction.set(messageRef, {
        id: messageId,
        outboxId: messageId,
        senderUid,
        recipientUid,
        participants: [senderUid, recipientUid],
        body,
        conversationId: normalizeString(data.conversationId),
        contextType: normalizeString(data.contextType || 'direct_message'),
        contextId: normalizeString(data.contextId),
        moderation: {
          state: decision.state,
          action: decision.action,
          score: decision.score,
          triggeredRules: decision.triggeredRules,
          providerConfigured: providerResult.configured === true,
          provider: providerResult.provider,
          providerState: providerResult.state,
          providerScore: providerResult.score,
          providerCategories: providerResult.categories || [],
          providerAudit: providerResult.auditMetadata || {},
        },
        status: 'delivered',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: false });
      transaction.set(snap.ref, {
        status: 'delivered',
        messageId,
        moderationState: decision.state,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  }
);


// Issuer-confirmed Hunter contracts; no client completion/stat authority.
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { createContractVerification } = require('./raider_contract_verification');
const raiderContractVerification = createContractVerification({
  db, bucket: admin.storage().bucket(), HttpsError,
  timestamp: () => admin.firestore.FieldValue.serverTimestamp(),
});
exports.submitRaiderContractEvidence = onCall(raiderContractVerification.submit);
exports.reviewRaiderContractEvidence = onCall(raiderContractVerification.review);

// Incident verification/discovery is separate from issuer-confirmed completion.
const { createRaiderContractIntelligence } = require('./raider_contract_intelligence');
const contractIntelligence = createRaiderContractIntelligence({
  db, bucket: admin.storage().bucket(), HttpsError,
  getAuthUser: uid => admin.auth().getUser(uid),
  timestamp: () => admin.firestore.FieldValue.serverTimestamp(),
  windowDays: process.env.CONTRACT_INTELLIGENCE_WINDOW_DAYS || 30,
});
exports.recordTradingBetrayal = onCall(contractIntelligence.recordBetrayal);
exports.attachRaiderReportEvidence = onCall(contractIntelligence.attachEvidence);
exports.moderateRaiderReport = onCall(contractIntelligence.moderateReport);
exports.discoverRaiderContracts = onCall(contractIntelligence.discover);
exports.acceptRaiderContract = onCall(contractIntelligence.accept);
exports.raiderAccountCases = onCall(contractIntelligence.accountStatus);
exports.challengeRaiderContract = onCall(contractIntelligence.challenge);
exports.reviewRaiderContractChallenge = onCall(contractIntelligence.reviewChallenge);
exports.expireRaiderContracts = onSchedule('every 60 minutes', contractIntelligence.expireContracts);
exports.withdrawRaiderContract = onDocumentWritten('arc_raider_reports/{reportId}', contractIntelligence.reportWithdrawn);

exports.raiderContractAdminContext = onCall(contractIntelligence.adminContext);
exports.auditRaiderContractLifecycle = onDocumentWritten('arc_raider_contracts/{contractId}', contractIntelligence.lifecycleChanged);
