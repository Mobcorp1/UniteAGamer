import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_subscription_plan.dart';
import '../models/uag_subscription_tier.dart';
import '../screens/uag_benefits_community_rewards_screen.dart';
import '../screens/uag_creator_programme_screen.dart';
import '../services/uag_checkout_service.dart';
import '../services/uag_entitlement_service.dart';
import '../widgets/uag_beta_founder_offer_panel.dart';

class MonetisationScreen extends StatefulWidget {
  static const routeName = '/monetisation';

  const MonetisationScreen({super.key});

  @override
  State<MonetisationScreen> createState() => _MonetisationScreenState();
}

class _MonetisationScreenState extends State<MonetisationScreen> {
  final UagEntitlementService _entitlementService = UagEntitlementService();
  final UagCheckoutService _checkoutService = UagCheckoutService();
  bool _checkoutBusy = false;

  Future<void> _startCheckout(String planId) async {
    if (_checkoutBusy) return;
    setState(() => _checkoutBusy = true);
    try {
      await _checkoutService.startCheckout(planId: planId);
    } on UagCheckoutException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkout could not be started. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _checkoutBusy = false);
    }
  }

  Future<void> _requestPayout(int amountPence) async {
    try {
      await _entitlementService.requestPayout(amountPence: amountPence);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout request submitted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit payout request. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Plans & Referrals',
        subtitle: 'Choose your access. Raid more. Earn when you grow UAG.',
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

          final activeTier =
              entitlement?.effectiveTier ?? UagSubscriptionTier.free;

          return ArcTacticalPageList(
            width: ArcPageWidth.wide,
            maxWidth: 1180,
            padding: ArcLayoutTokens.pagePadding(context),
            children: [
              _CommercialHero(activeTier: activeTier),
              const SizedBox(height: ArcUiTokens.gapM),
              if (entitlement != null) ...[
                _CurrentAccessCard(
                  tier: activeTier,
                  subscriptionStatus: entitlement.subscriptionStatus,
                  pendingPence: entitlement.pendingBalancePence,
                  availablePence: entitlement.availableBalancePence,
                  totalEarnedPence: entitlement.totalEarnedPence,
                  hasAdminBypass: entitlement.hasAdminBypass,
                  onRequestPayout:
                      entitlement.availableBalancePence >=
                          entitlement.limits.payoutThresholdPence
                      ? () => _requestPayout(entitlement.availableBalancePence)
                      : null,
                  onOpenCommunity: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UagBenefitsCommunityRewardsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapM),
                UagBetaFounderOfferPanel(
                  entitlement: entitlement,
                  checkoutBusy: _checkoutBusy,
                  onCheckout: _startCheckout,
                ),
                const SizedBox(height: ArcUiTokens.gapM),
              ],
              _SectionHeading(
                title: 'CHOOSE YOUR ACCESS',
                subtitle:
                    'Free keeps the network moving. Essential raises the limits. Premium is the complete UAG experience.',
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final cards = UagSubscriptionPlan.plans
                      .map(
                        (plan) => _PlanCard(
                          plan: plan,
                          activeTier: activeTier,
                          checkoutBusy: _checkoutBusy,
                          onCheckout: _startCheckout,
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
              const SizedBox(height: ArcUiTokens.gapM),
              _EarnGateway(
                onCommunity: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UagBenefitsCommunityRewardsScreen(),
                  ),
                ),
                onCreator: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UagCreatorProgrammeScreen(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommercialHero extends StatelessWidget {
  const _CommercialHero({required this.activeTier});

  final UagSubscriptionTier activeTier;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.workspace_premium_rounded,
      title: 'UAG ACCESS COMMAND',
      subtitle: 'Simple plans. Flexible Premium passes. Real recurring referral earnings.',
      accent: ArcUiTokens.secondaryAccent,
      child: Wrap(
        spacing: ArcUiTokens.gapS,
        runSpacing: ArcUiTokens.gapS,
        children: [
          _Tag('${activeTier.label.toUpperCase()} ACTIVE', ArcUiTokens.primaryAccent),
          const _Tag('PREMIUM £9.99 / MONTH', ArcUiTokens.secondaryAccent),
          const _Tag('REFER & EARN 5% → 15%', ArcUiTokens.secondaryAccent),
          const _Tag('PREMIUM REFERRAL BOOST +2.5PP', ArcUiTokens.primaryAccent),
        ],
      ),
    );
  }
}

class _CurrentAccessCard extends StatelessWidget {
  const _CurrentAccessCard({
    required this.tier,
    required this.subscriptionStatus,
    required this.pendingPence,
    required this.availablePence,
    required this.totalEarnedPence,
    required this.hasAdminBypass,
    required this.onRequestPayout,
    required this.onOpenCommunity,
  });

  final UagSubscriptionTier tier;
  final String subscriptionStatus;
  final int pendingPence;
  final int availablePence;
  final int totalEarnedPence;
  final bool hasAdminBypass;
  final VoidCallback? onRequestPayout;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.account_balance_wallet_outlined,
      title: 'CURRENT ACCESS',
      subtitle: hasAdminBypass
          ? 'Admin/dev bypass active.'
          : '${tier.label} • ${subscriptionStatus.toUpperCase()}',
      accent: ArcUiTokens.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              _WalletStat('PENDING', _money(pendingPence)),
              _WalletStat('AVAILABLE', _money(availablePence)),
              _WalletStat('LIFETIME', _money(totalEarnedPence)),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.secondaryAccent,
                ),
                onPressed: onOpenCommunity,
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('OPEN COMMUNITY COMMAND'),
              ),
              OutlinedButton.icon(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                ),
                onPressed: onRequestPayout,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('REQUEST PAYOUT'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.activeTier,
    required this.checkoutBusy,
    required this.onCheckout,
  });

  final UagSubscriptionPlan plan;
  final UagSubscriptionTier activeTier;
  final bool checkoutBusy;
  final ValueChanged<String> onCheckout;

  @override
  Widget build(BuildContext context) {
    final active = plan.tier == activeTier;
    final premium = plan.tier == UagSubscriptionTier.premium;
    final accent = premium
        ? ArcUiTokens.secondaryAccent
        : plan.tier == UagSubscriptionTier.essential
        ? ArcUiTokens.primaryAccent
        : ArcUiTokens.textTertiary;
    final annualSavingPence = plan.monthlyPricePence <= 0
        ? 0
        : (plan.monthlyPricePence * 12) - plan.yearlyPricePence;

    return Container(
      padding: const EdgeInsets.all(ArcUiTokens.gapL),
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: premium ? 0.44 : 0.24,
        selected: active,
        glow: premium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.shortName.toUpperCase(),
                  style: ArcUiTokens.sectionTitle(fontSize: 19, color: accent),
                ),
              ),
              if (premium)
                const _Tag('BEST UAG', ArcUiTokens.secondaryAccent),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapXS),
          Text(
            plan.monthlyPriceLabel,
            style: ArcUiTokens.numeric(fontSize: 23, color: accent),
          ),
          Text(
            plan.yearlyPriceLabel,
            style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
          ),
          if (annualSavingPence > 0)
            Text(
              'Annual saves ${_money(annualSavingPence)} vs monthly.',
              style: ArcUiTokens.metadata(color: ArcUiTokens.success),
            ),
          const SizedBox(height: ArcUiTokens.gapM),
          Text(plan.positioning, style: ArcUiTokens.bodySmall()),
          const SizedBox(height: ArcUiTokens.gapM),
          for (final feature in plan.features.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 17, color: accent),
                  const SizedBox(width: 7),
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
          const SizedBox(height: ArcUiTokens.gapM),
          if (plan.tier == UagSubscriptionTier.free)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: ArcUiTokens.textButtonStyle(accent: accent),
                onPressed: null,
                child: Text(active ? 'CURRENT ACCESS' : 'FREE ACCESS'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: ArcUiTokens.textButtonStyle(accent: accent),
                    onPressed: active || checkoutBusy
                        ? null
                        : () => onCheckout(_checkoutPlanId('monthly')),
                    child: const Text('MONTHLY'),
                  ),
                ),
                const SizedBox(width: ArcUiTokens.gapS),
                Expanded(
                  child: FilledButton(
                    style: ArcUiTokens.textButtonStyle(
                      accent: accent,
                      primary: true,
                    ),
                    onPressed: active || checkoutBusy
                        ? null
                        : () => onCheckout(_checkoutPlanId('yearly')),
                    child: Text(active ? 'CURRENT' : 'ANNUAL'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _checkoutPlanId(String period) {
    final tier = switch (plan.tier) {
      UagSubscriptionTier.essential => 'essential',
      UagSubscriptionTier.premium => 'premium',
      UagSubscriptionTier.free => 'free',
    };
    return '${tier}_$period';
  }
}

class _EarnGateway extends StatelessWidget {
  const _EarnGateway({required this.onCommunity, required this.onCreator});

  final VoidCallback onCommunity;
  final VoidCallback onCreator;

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.hub_outlined,
      title: 'GROW UAG. SHARE THE VALUE.',
      subtitle:
          'Every Raider can refer. Approved Creators unlock the advanced programme and higher creator tooling.',
      accent: ArcUiTokens.secondaryAccent,
      child: Wrap(
        spacing: ArcUiTokens.gapS,
        runSpacing: ArcUiTokens.gapS,
        children: [
          FilledButton.icon(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.secondaryAccent,
              primary: true,
            ),
            onPressed: onCommunity,
            icon: const Icon(Icons.groups_2_outlined),
            label: const Text('REFER & EARN'),
          ),
          OutlinedButton.icon(
            style: ArcUiTokens.textButtonStyle(
              accent: ArcUiTokens.primaryAccent,
            ),
            onPressed: onCreator,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('CREATOR PROGRAMME'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ArcUiTokens.sectionTitle(
            fontSize: 17,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        const SizedBox(height: ArcUiTokens.gapXS),
        Text(subtitle, style: ArcUiTokens.bodySmall()),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: color),
      child: Text(label, style: ArcUiTokens.label(color: color)),
    );
  }
}

class _WalletStat extends StatelessWidget {
  const _WalletStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArcUiTokens.label()),
          const SizedBox(height: 2),
          Text(
            value,
            style: ArcUiTokens.numeric(
              fontSize: 17,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

String _money(int pence) => '£${(pence / 100).toStringAsFixed(2)}';
