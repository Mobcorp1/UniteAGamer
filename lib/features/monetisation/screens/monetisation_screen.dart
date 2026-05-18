import 'package:flutter/material.dart';
import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

import '../models/uag_subscription_plan.dart';
import '../models/uag_subscription_tier.dart';
import '../services/uag_entitlement_service.dart';

class MonetisationScreen extends StatefulWidget {
  static const routeName = '/monetisation';

  const MonetisationScreen({super.key});

  @override
  State<MonetisationScreen> createState() => _MonetisationScreenState();
}

class _MonetisationScreenState extends State<MonetisationScreen> {
  final UagEntitlementService _entitlementService = UagEntitlementService();

  Future<void> _ensureReferralCode() async {
    try {
      final code = await _entitlementService.ensureMyReferralCode();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Referral code ready: $code')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _requestPayout(int amountPence) async {
    try {
      await _entitlementService.requestPayout(amountPence: amountPence);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout request submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'Plans & Referrals',
        subtitle: 'Free, Essential, Premium, referrals and wallet.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: StreamBuilder(
              stream: _entitlementService.watchMyEntitlement(),
              builder: (context, snapshot) {
                final entitlement = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting &&
                    entitlement == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }

                return ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    if (entitlement != null)
                      _CurrentPlanCard(
                        tier: entitlement.tier,
                        subscriptionStatus: entitlement.subscriptionStatus,
                        referralCode: entitlement.referralCode,
                        pendingPence: entitlement.pendingBalancePence,
                        availablePence: entitlement.availableBalancePence,
                        totalEarnedPence: entitlement.totalEarnedPence,
                        hasAdminBypass: entitlement.hasAdminBypass,
                        onGenerateReferralCode: _ensureReferralCode,
                        onRequestPayout:
                            entitlement.availableBalancePence >=
                                entitlement.limits.payoutThresholdPence
                            ? () => _requestPayout(
                                entitlement.availableBalancePence,
                              )
                            : null,
                      ),
                    const SizedBox(height: AppTheme.spaceL),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 880;
                        final cards = UagSubscriptionPlan.plans
                            .map(
                              (plan) => _PlanCard(
                                plan: plan,
                                activeTier:
                                    entitlement?.tier ??
                                    UagSubscriptionTier.free,
                              ),
                            )
                            .toList(growable: false);
                        if (!wide) {
                          return Column(
                            children: cards
                                .map(
                                  (card) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppTheme.spaceM,
                                    ),
                                    child: card,
                                  ),
                                )
                                .toList(growable: false),
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: cards
                              .map(
                                (card) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: card,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    _LaunchNotesCard(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.tier,
    required this.subscriptionStatus,
    required this.referralCode,
    required this.pendingPence,
    required this.availablePence,
    required this.totalEarnedPence,
    required this.hasAdminBypass,
    required this.onGenerateReferralCode,
    required this.onRequestPayout,
  });

  final UagSubscriptionTier tier;
  final String subscriptionStatus;
  final String? referralCode;
  final int pendingPence;
  final int availablePence;
  final int totalEarnedPence;
  final bool hasAdminBypass;
  final VoidCallback onGenerateReferralCode;
  final VoidCallback? onRequestPayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Access',
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            hasAdminBypass
                ? 'Admin/dev bypass active. You can access everything while testing.'
                : '${tier.label} • $subscriptionStatus',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill('Referral Code', referralCode ?? 'Not generated'),
              _Pill('Pending', _money(pendingPence)),
              _Pill('Available', _money(availablePence)),
              _Pill('Total Earned', _money(totalEarnedPence)),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onGenerateReferralCode,
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text('Create Referral Code'),
              ),
              OutlinedButton.icon(
                onPressed: onRequestPayout,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Request Payout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.activeTier});

  final UagSubscriptionPlan plan;
  final UagSubscriptionTier activeTier;

  @override
  Widget build(BuildContext context) {
    final active = plan.tier == activeTier;
    final highlight = plan.tier == UagSubscriptionTier.premium;
    final borderColor = active
        ? AppTheme.warningAmber
        : highlight
        ? AppTheme.neonPink.withValues(alpha: 0.36)
        : AppTheme.neonCyan.withValues(alpha: 0.24);

    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(borderColor: borderColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: AppTheme.tradingHeading(
              fontSize: 24,
              color: highlight ? AppTheme.neonPink : AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.monthlyPriceLabel} • ${plan.yearlyPriceLabel}',
            style: AppTheme.bodyTextStyle(
              fontSize: 15,
              color: Colors.white,
              isBold: true,
            ),
          ),
          if (plan.creatorOnboardingDiscountPercent > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${plan.creatorOnboardingDiscountPercent}% creator onboarding discount available for approved early creators.',
              style: const TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
          const SizedBox(height: AppTheme.spaceM),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: highlight ? AppTheme.neonPink : AppTheme.neonCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: active || plan.tier == UagSubscriptionTier.free
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Stripe checkout endpoint is wired in Cloud Functions. Add Stripe keys and price IDs before enabling live checkout.',
                          ),
                        ),
                      );
                    },
              child: Text(active ? 'Current Plan' : 'Upgrade'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchNotesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.warningAmber.withValues(alpha: 0.24),
      ),
      child: const Text(
        'Launch model: Free users get strict weekly limits and ads. Essential users get 5x weekly limits, reduced ads, 10% follower discounts and 10% recurring referral commission. Premium users get unlimited access, no ads, 20% follower discounts and 20% recurring referral commission. Referral payouts stay pending for 30 days and become withdrawable after refund risk has passed.',
        style: TextStyle(color: Colors.white70, height: 1.4),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: AppTheme.tradingPillDecoration(color: AppTheme.neonCyan),
      child: Text(
        '$label: $value',
        style: AppTheme.bodyTextStyle(
          fontSize: 12,
          color: AppTheme.neonCyan,
          isBold: true,
        ),
      ),
    );
  }
}

String _money(int pence) => '£${(pence / 100).toStringAsFixed(2)}';
