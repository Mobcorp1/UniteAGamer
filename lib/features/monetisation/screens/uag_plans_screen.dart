import 'package:flutter/material.dart';

import 'package:uag_traders_hub/build/app_bar.dart';
import 'package:uag_traders_hub/build/app_drawer.dart';
import 'package:uag_traders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_traders_hub/features/monetisation/repositories/uag_monetisation_repository.dart';
import 'package:uag_traders_hub/features/monetisation/widgets/uag_impact_pots_panel.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagPlansScreen extends StatelessWidget {
  static const routeName = '/monetisation/plans';

  const UagPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagMonetisationRepository();
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: const UagAppBar(
        title: 'UAG Plans',
        subtitle: 'Free, Essential and Premium access.',
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          const Positioned.fill(child: StaticWatermark()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ListView(
                  padding: AppTheme.pagePadding,
                  children: [
                    _hero(context),
                    const SizedBox(height: AppTheme.spaceL),
                    const UagImpactPotsPanel(showAdminDetail: false),
                    const SizedBox(height: AppTheme.spaceL),
                    StreamBuilder<UagEntitlement>(
                      stream: repository.watchMyEntitlement(),
                      builder: (context, snapshot) {
                        final entitlement = snapshot.data;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;
                            final cards = UagPlans.all
                                .map(
                                  (plan) => _PlanCard(
                                    plan: plan,
                                    isCurrentPlan: entitlement?.tier == plan.tier,
                                  ),
                                )
                                .toList(growable: false);
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: cards
                                    .map((card) => Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: AppTheme.spaceM),
                                            child: card,
                                          ),
                                        ))
                                    .toList(growable: false),
                              );
                            }
                            return Column(
                              children: cards
                                  .map((card) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                                        child: card,
                                      ))
                                  .toList(growable: false),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                    _paymentsNote(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.28),
        radius: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how hard you want UAG to work for you.',
            style: AppTheme.tradingHeading(fontSize: 26, color: AppTheme.neonCyan),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Free keeps the app open to every player. Essential gives regular users enough weekly power to trade and match properly. Premium removes limits, removes ads and unlocks full creator earnings.',
            style: AppTheme.bodyTextStyle(fontSize: 15, color: AppTheme.tradingMutedText),
          ),
        ],
      ),
    );
  }

  Widget _paymentsNote() {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.warningAmber.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment setup',
            style: AppTheme.tradingHeading(fontSize: 22, color: AppTheme.warningAmber),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Stripe Checkout is wired for cards, Apple Pay, Google Pay and Bacs Direct Debit-ready subscriptions. PayPal is intentionally not active in this pass so subscriptions, referrals and webhook entitlements stay clean at launch.',
            style: AppTheme.bodyTextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.isCurrentPlan});

  final UagPlanDefinition plan;
  final bool isCurrentPlan;

  @override
  Widget build(BuildContext context) {
    final highlight = plan.tier == UagPlanTier.premium
        ? AppTheme.neonPink
        : plan.tier == UagPlanTier.essential
            ? AppTheme.neonCyan
            : Colors.white70;
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: highlight.withValues(alpha: isCurrentPlan ? 0.5 : 0.22),
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.tier.label,
                  style: AppTheme.tradingHeading(fontSize: 24, color: highlight),
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: AppTheme.pillPadding,
                  decoration: AppTheme.tradingPillDecoration(color: highlight),
                  child: Text(
                    'CURRENT',
                    style: AppTheme.bodyTextStyle(fontSize: 11, color: highlight, isBold: true),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            '${plan.monthlyPriceLabel}/month',
            style: AppTheme.tradingHeading(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.yearlyPriceLabel}/year',
            style: AppTheme.bodyTextStyle(fontSize: 13, color: AppTheme.tradingMutedText),
          ),
          const SizedBox(height: AppTheme.spaceM),
          _metric('Trades', plan.isUnlimited ? 'Unlimited' : '${plan.weeklyTrades}/week'),
          _metric('Match searches', plan.isUnlimited ? 'Unlimited' : '${plan.weeklyMatchSearches}/week'),
          _metric('Intel hints', plan.isUnlimited ? 'Unlimited' : '${plan.weeklyIntelHints}/week'),
          _metric('Ads', plan.adsLabel),
          _metric('Follower discount', plan.creatorDiscountPercent == 0 ? 'Referral perks only' : '${plan.creatorDiscountPercent}%'),
          _metric('Creator commission', plan.creatorCommissionPercent == 0 ? 'Perks' : '${plan.creatorCommissionPercent}% recurring'),
          _metric('Charity pot', plan.charityProfitPercent == 0 ? 'Not allocated' : '${plan.charityProfitPercent}% of net profit'),
          const SizedBox(height: AppTheme.spaceM),
          ...plan.benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 17, color: highlight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white70),
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
              onPressed: isCurrentPlan ? null : () {},
              child: Text(plan.tier == UagPlanTier.free ? 'Current free access' : 'Checkout enabled via Stripe function'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTheme.bodyTextStyle(fontSize: 13, color: AppTheme.tradingMutedText)),
          ),
          Text(value, style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white, isBold: true)),
        ],
      ),
    );
  }
}
