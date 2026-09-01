import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_monetisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_impact_pots_panel.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_match_intelligence_comparison_card.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

class UagPlansScreen extends StatelessWidget {
  static const routeName = '/monetisation/plans';

  const UagPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagMonetisationRepository();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'UAG Plans',
        subtitle: 'Free, Essential and Premium access.',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1180,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          _hero(context),
          const UagImpactPotsPanel(showAdminDetail: false),
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
                      children: [
                        for (var index = 0; index < cards.length; index++) ...[
                          if (index > 0)
                            const SizedBox(width: ArcUiTokens.gapM),
                          Expanded(child: cards[index]),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        if (index > 0) const SizedBox(height: ArcUiTokens.gapM),
                        cards[index],
                      ],
                    ],
                  );
                },
              );
            },
          ),
          const UagMatchIntelligenceComparisonCard(),
          _paymentsNote(),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return const ArcTacticalPanel(
      icon: Icons.workspace_premium_outlined,
      title: 'Choose how hard you want UAG to work for you.',
      subtitle:
          'Free keeps the app open to every player. Essential gives regular users enough weekly power to trade and match properly. Premium removes limits, removes ads and unlocks full creator earnings.',
      accent: ArcUiTokens.primaryAccent,
      child: SizedBox.shrink(),
    );
  }

  Widget _paymentsNote() {
    return ArcTacticalPanel(
      icon: Icons.payments_outlined,
      title: 'Payment setup',
      accent: ArcUiTokens.warning,
      child: Text(
        'Stripe Checkout is wired for cards, Apple Pay, Google Pay and Bacs Direct Debit-ready subscriptions. PayPal is intentionally not active in this pass so subscriptions, referrals and webhook entitlements stay clean at launch.',
        style: ArcUiTokens.body(fontSize: 13),
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
    final accent = isCurrentPlan
        ? ArcUiTokens.warning
        : plan.tier == UagPlanTier.premium
        ? ArcUiTokens.secondaryAccent
        : plan.tier == UagPlanTier.essential
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textTertiary;
    return ArcTacticalPanel(
      accent: accent,
      padding: const EdgeInsets.all(ArcUiTokens.gapL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.tier.label,
                  style: ArcUiTokens.sectionTitle(fontSize: 20, color: accent),
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: ArcUiTokens.chipPadding,
                  decoration: ArcUiTokens.chipDecoration(
                    color: accent,
                    selected: true,
                  ),
                  child: Text(
                    'CURRENT',
                    style: ArcUiTokens.label(color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            '${plan.monthlyPriceLabel}/month',
            style: ArcUiTokens.numeric(
              fontSize: 24,
              color: ArcUiTokens.textPrimary,
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapXS),
          Text('${plan.yearlyPriceLabel}/year', style: ArcUiTokens.bodySmall()),
          const SizedBox(height: ArcUiTokens.gapM),
          _metric(
            'Trades',
            plan.isUnlimited ? 'Unlimited' : '${plan.weeklyTrades}/week',
          ),
          _metric(
            'Match searches',
            plan.isUnlimited ? 'Unlimited' : '${plan.weeklyMatchSearches}/week',
          ),
          _metric(
            'Intel hints',
            plan.isUnlimited ? 'Unlimited' : '${plan.weeklyIntelHints}/week',
          ),
          _metric('Ads', plan.adsLabel),
          _metric(
            'Follower discount',
            plan.creatorDiscountPercent == 0
                ? 'Referral perks only'
                : '${plan.creatorDiscountPercent}%',
          ),
          _metric(
            'Creator commission',
            plan.creatorCommissionPercent == 0
                ? 'Perks'
                : '${plan.creatorCommissionPercent}% recurring',
          ),
          _metric(
            'Charity pot',
            plan.charityProfitPercent == 0
                ? 'Not allocated'
                : '${plan.charityProfitPercent}% of net profit',
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          ...plan.benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 17, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
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
              onPressed: isCurrentPlan ? null : () {},
              child: Text(
                plan.tier == UagPlanTier.free
                    ? 'Current free access'
                    : 'Checkout enabled via Stripe function',
              ),
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
          Expanded(child: Text(label, style: ArcUiTokens.bodySmall())),
          Text(
            value,
            style: ArcUiTokens.body(
              fontSize: 13,
              color: ArcUiTokens.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
