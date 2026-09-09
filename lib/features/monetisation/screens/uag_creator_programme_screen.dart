import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/build/app_bar.dart';
import 'package:uag_arc_raiders_hub/build/app_drawer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_layout_system.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_creator_commercial_policy.dart';
import '../models/uag_creator_live_models.dart';
import '../models/uag_creator_programme_models.dart';
import '../repositories/uag_creator_live_repository.dart';
import '../widgets/uag_creator_community_arsenal_panel.dart';
import '../widgets/uag_creator_reward_access_panel.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_creator_application_panel.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/widgets/uag_creator_commission_ledger_panel.dart';

import '../widgets/uag_creator_commission_rate_panel.dart';

class UagCreatorProgrammeScreen extends StatelessWidget {
  const UagCreatorProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagCreatorLiveRepository();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Creator Programme',
        subtitle:
            'Earn recurring commission. Reward your community. Grow with UAG.',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1180,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          _LiveCreatorCommandCentre(repository: repository),
          const SizedBox(height: ArcUiTokens.gapM),
          const ArcTacticalPanel(
            icon: Icons.campaign_outlined,
            title: 'UAG Creator Programme',
            subtitle:
                'Creators contribute to the platform and unlock better earnings and community tools as their active paid audience grows.',
            accent: ArcUiTokens.primaryAccent,
            child: _Principles(),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          const _CreatorUpgradeCard(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _LevelGrid(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _CommercialRules(),
        ],
      ),
    );
  }
}

class _LiveCreatorCommandCentre extends StatelessWidget {
  const _LiveCreatorCommandCentre({required this.repository});
  final UagCreatorLiveRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagCreatorProgrammeApplication?>(
      stream: repository.watchMyApplication(),
      builder: (context, appSnapshot) {
        final application = appSnapshot.data;
        if (application == null) {
          return const ArcTacticalPanel(
            icon: Icons.person_add_alt_1,
            title: 'Creator Command Centre',
            subtitle:
                'No Creator Programme application is linked to this account yet.',
            accent: ArcUiTokens.secondaryAccent,
            child: Text(
              'The programme package is shown below. Application and approval use the existing Creator Programme workflow.',
            ),
          );
        }
        return StreamBuilder<UagCreatorLiveDashboard>(
          stream: repository.watchMyDashboard(),
          builder: (context, dashSnapshot) {
            final dash =
                dashSnapshot.data ??
                UagCreatorLiveDashboard(
                  uid: application.uid,
                  creatorId: application.creatorId,
                );
            final approved =
                application.status == UagCreatorApplicationStatus.approved;
            return ArcTacticalPanel(
              icon: Icons.radar,
              title: 'Creator Command Centre',
              subtitle: approved
                  ? 'Live creator identity, points, earnings and monthly community inventory.'
                  : application.status.label,
              accent: approved
                  ? ArcUiTokens.primaryAccent
                  : ArcUiTokens.secondaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Metric(
                        'Creator ID',
                        application.creatorId.isEmpty
                            ? 'Pending'
                            : application.creatorId,
                      ),
                      _Metric(
                        'Points',
                        dash.creatorPoints.toStringAsFixed(
                          dash.creatorPoints % 1 == 0 ? 0 : 1,
                        ),
                      ),
                      _Metric('Level', dash.level?.name ?? 'Unranked'),
                      _Metric(
                        'Commission',
                        '${dash.commissionPercent.toStringAsFixed(dash.commissionPercent % 1 == 0 ? 0 : 1)}%',
                      ),
                      _Metric('Free referrals', '${dash.activeFreeUsers}'),
                      _Metric('Essential', '${dash.essentialSubscribers}'),
                      _Metric('Premium', '${dash.premiumSubscribers}'),
                      _Metric(
                        'Approved commission',
                        '£${(dash.approvedCommissionPence / 100).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  if (approved) ...[
                    const SizedBox(height: 14),
                    UagCreatorCommissionRatePanel(
                      creatorPoints: dash.creatorPoints,
                    ),
                    const SizedBox(height: 14),
                    _MonthlyArsenal(inventory: dash.monthlyInventory),
                    const SizedBox(height: 14),
                    UagCreatorCommunityArsenalPanel(
                      inventory: dash.monthlyInventory,
                    ),
                    const SizedBox(height: 14),
                    const UagCreatorApplicationPanel(),
                    const UagCreatorCommissionLedgerPanel(),
                    const UagCreatorRewardAccessPanel(),
                    const SizedBox(height: 14),
                    StreamBuilder<List<UagCreatorCodeRecord>>(
                      stream: repository.watchMyCodeRequests(),
                      builder: (context, codeSnapshot) {
                        final codes =
                            codeSnapshot.data ?? const <UagCreatorCodeRecord>[];
                        if (codes.isEmpty) {
                          return const Text(
                            'No creator campaign codes requested yet.',
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: codes
                              .map(
                                (code) => _Chip(
                                  '${code.code} • ${code.status.replaceAll('_', ' ')}',
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MonthlyArsenal extends StatelessWidget {
  const _MonthlyArsenal({required this.inventory});
  final UagCreatorMonthlyInventory inventory;
  @override
  Widget build(BuildContext context) {
    final month = inventory.monthKey.isEmpty
        ? 'Awaiting monthly refresh'
        : inventory.monthKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMUNITY ARSENAL • $month',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: ArcUiTokens.secondaryAccent,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip('${inventory.essential7DayRemaining} Essential 7-day'),
            _Chip('${inventory.essentialMonthRemaining} Essential month'),
            _Chip('${inventory.premium7DayRemaining} Premium 7-day'),
            _Chip('${inventory.premiumMonthRemaining} Premium month'),
            if (inventory.annualPremiumRemaining > 0)
              _Chip('${inventory.annualPremiumRemaining} Annual Premium'),
            if (inventory.seasonalCampaignAccess)
              const _Chip('Seasonal campaigns unlocked'),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 135),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: ArcUiTokens.primaryAccent.withValues(alpha: .28),
      ),
      color: Colors.black.withValues(alpha: .16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: ArcUiTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _Principles extends StatelessWidget {
  const _Principles();
  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _Chip('Essential = 1 point'),
      _Chip('Premium = 1.5 points'),
      _Chip('5% → 20% recurring'),
      _Chip('Monthly reward drops'),
      _Chip('30-day commission validation'),
      _Chip('30-day tier grace'),
    ],
  );
}

class _CreatorUpgradeCard extends StatelessWidget {
  const _CreatorUpgradeCard();
  @override
  Widget build(BuildContext context) => const ArcTacticalPanel(
    icon: Icons.workspace_premium_outlined,
    title: 'Creator subscription benefit',
    subtitle: 'No automatic free Premium.',
    accent: ArcUiTokens.secondaryAccent,
    child: Text(
      "Approved active creators can buy Premium monthly for £7.99 — the Essential monthly price. The £2 Creator benefit is applied only to the approved creator's own Premium monthly checkout; it is not free Premium.",
    ),
  );
}

class _LevelGrid extends StatelessWidget {
  const _LevelGrid();
  @override
  Widget build(BuildContext context) => ArcTacticalPanel(
    icon: Icons.stacked_line_chart,
    title: 'Recurring commission ladder',
    subtitle:
        'Your rate is based on active Creator Points, not lifetime registrations.',
    accent: ArcUiTokens.primaryAccent,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final level in UagCreatorCommercialPolicy.levels)
              SizedBox(
                width: width,
                child: _LevelCard(level: level),
              ),
          ],
        );
      },
    ),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});
  final UagCreatorLevel level;
  @override
  Widget build(BuildContext context) {
    final range = level.maxPoints == null
        ? '100+'
        : '${level.minPoints.toStringAsFixed(0)}–${level.maxPoints!.floor()}';
    final a = level.allocation;
    final rewards = <String>[
      if (a.essential7Day > 0) '${a.essential7Day}× Essential 7-day',
      if (a.essentialMonth > 0) '${a.essentialMonth}× Essential month',
      if (a.premium7Day > 0) '${a.premium7Day}× Premium 7-day',
      if (a.premiumMonth > 0) '${a.premiumMonth}× Premium month',
      if (a.annualPremiumPerQuarter > 0)
        '${a.annualPremiumPerQuarter}× annual Premium / quarter',
      if (a.seasonalCampaignAccess) 'Seasonal campaign access',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: ArcUiTokens.primaryAccent.withValues(alpha: .32),
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: .18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            '$range points • ${level.commissionPercent.toStringAsFixed(level.commissionPercent % 1 == 0 ? 0 : 1)}% recurring',
            style: const TextStyle(
              color: ArcUiTokens.primaryAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final reward in rewards)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $reward', style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _CommercialRules extends StatelessWidget {
  const _CommercialRules();
  @override
  Widget build(BuildContext context) => const ArcTacticalPanel(
    icon: Icons.shield_outlined,
    title: 'Commercial protections',
    subtitle:
        'Designed to reward genuine growth without giving away the business.',
    accent: ArcUiTokens.secondaryAccent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• Commission is calculated from eligible net subscription revenue actually received.',
        ),
        Text(
          '• Free referrals are tracked but do not earn recurring cash commission at launch.',
        ),
        Text(
          '• Referral attribution captured by the client remains pending until validated against an approved creator identity and billing event.',
        ),
        Text(
          '• Refunds, chargebacks, self-referrals and fraudulent referrals do not qualify.',
        ),
        Text(
          '• Giveaway periods do not generate commission until the recipient becomes a genuine paying subscriber.',
        ),
        Text(
          '• Discounts do not stack unless a UAG campaign explicitly permits it.',
        ),
        Text('• Commission validates for 30 days before becoming payable.'),
        Text(
          '• A 30-day grace period protects a creator tier from normal short-term churn.',
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: ArcUiTokens.primaryAccent.withValues(alpha: .35),
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
