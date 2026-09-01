import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_subscription_plan.dart';
import '../models/uag_subscription_tier.dart';
import '../services/uag_entitlement_service.dart';
import '../widgets/uag_match_intelligence_comparison_card.dart';

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
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Plans & Referrals',
        subtitle: 'Free, Essential, Premium, referrals and wallet.',
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder(
        stream: _entitlementService.watchMyEntitlement(),
        builder: (context, snapshot) {
          final entitlement = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting &&
              entitlement == null) {
            return const ArcTacticalPageBody(
              width: ArcPageWidth.form,
              scrollable: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: ArcUiTokens.primaryAccent,
                ),
              ),
            );
          }

          return ArcTacticalPageList(
            width: ArcPageWidth.wide,
            maxWidth: 1180,
            padding: ArcLayoutTokens.pagePadding(context),
            children: [
              const ArcTacticalPanel(
                icon: Icons.workspace_premium_outlined,
                title: 'Access Command',
                subtitle:
                    'Plan limits, referrals, wallet state and launch entitlement controls.',
                accent: ArcUiTokens.primaryAccent,
                child: SizedBox.shrink(),
              ),
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
                      ? () => _requestPayout(entitlement.availableBalancePence)
                      : null,
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 880;
                  final cards = UagSubscriptionPlan.plans
                      .map(
                        (plan) => _PlanCard(
                          plan: plan,
                          activeTier:
                              entitlement?.tier ?? UagSubscriptionTier.free,
                        ),
                      )
                      .toList(growable: false);
                  if (!wide) {
                    return Column(
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          if (index > 0)
                            const SizedBox(height: ArcUiTokens.gapM),
                          cards[index],
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        if (index > 0) const SizedBox(width: ArcUiTokens.gapM),
                        Expanded(child: cards[index]),
                      ],
                    ],
                  );
                },
              ),
              const UagMatchIntelligenceComparisonCard(),
              _LaunchNotesCard(),
            ],
          );
        },
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
    return ArcTacticalPanel(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Current Access',
      accent: ArcUiTokens.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasAdminBypass
                ? 'Admin/dev bypass active. You can access everything while testing.'
                : '${tier.label} - $subscriptionStatus',
            style: ArcUiTokens.body(fontSize: 13),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
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
          const SizedBox(height: ArcUiTokens.gapM),
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
    final accent = active
        ? ArcUiTokens.warning
        : highlight
        ? ArcUiTokens.secondaryAccent
        : ArcUiTokens.primaryAccent;

    return ArcTacticalPanel(
      accent: accent,
      padding: const EdgeInsets.all(ArcUiTokens.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: ArcUiTokens.sectionTitle(fontSize: 20, color: accent),
          ),
          const SizedBox(height: ArcUiTokens.gapXS),
          Text(
            '${plan.monthlyPriceLabel} - ${plan.yearlyPriceLabel}',
            style: ArcUiTokens.body(
              fontSize: 15,
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
          if (plan.creatorOnboardingDiscountPercent > 0) ...[
            const SizedBox(height: ArcUiTokens.gapXS),
            Text(
              '${plan.creatorOnboardingDiscountPercent}% creator onboarding discount available for approved early creators.',
              style: ArcUiTokens.bodySmall(),
            ),
          ],
          const SizedBox(height: ArcUiTokens.gapM),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: ArcUiTokens.bodySmall(
                        color: ArcUiTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
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
    return ArcTacticalPanel(
      icon: Icons.campaign_outlined,
      title: 'Launch Model',
      accent: ArcUiTokens.warning,
      child: Text(
        'Launch model: Free users get strict weekly limits and ads. Essential users get 5x weekly limits, no ads, 10% follower discounts and 10% recurring referral commission. Premium users get unlimited access, no ads, 20% follower discounts and 20% recurring referral commission. Referral payouts stay pending for 30 days and become withdrawable after refund risk has passed.',
        style: ArcUiTokens.body(fontSize: 13),
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
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: ArcUiTokens.primaryAccent),
      child: Text(
        '$label: $value',
        style: ArcUiTokens.label(color: ArcUiTokens.primaryAccent),
      ),
    );
  }
}

String _money(int pence) => 'GBP ${(pence / 100).toStringAsFixed(2)}';
