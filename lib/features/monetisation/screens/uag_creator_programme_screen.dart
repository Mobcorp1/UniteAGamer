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
import '../widgets/uag_creator_application_panel.dart';
import '../widgets/uag_creator_commission_ledger_panel.dart';
import '../widgets/uag_creator_commission_rate_panel.dart';
import '../widgets/uag_creator_community_arsenal_panel.dart';
import '../widgets/uag_creator_reward_access_panel.dart';

class UagCreatorProgrammeScreen extends StatelessWidget {
  const UagCreatorProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagCreatorLiveRepository();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const UagAppBar(
        title: 'Creator Programme',
        subtitle: 'Creator earnings • campaigns • community arsenal',
      ),
      drawer: const AppDrawer(),
      body: ArcTacticalPageList(
        width: ArcPageWidth.wide,
        maxWidth: 1080,
        padding: ArcLayoutTokens.pagePadding(context),
        children: [
          const ArcTacticalPanel(
            icon: Icons.campaign_outlined,
            title: 'CREATOR COMMAND CENTRE',
            subtitle:
                'A dedicated commercial programme for approved creators who drive genuine paid UAG growth.',
            accent: ArcUiTokens.secondaryAccent,
            child: Wrap(
              spacing: ArcUiTokens.gapS,
              runSpacing: ArcUiTokens.gapS,
              children: [
                _Chip('7.5% → 20% BASE', ArcUiTokens.secondaryAccent),
                _Chip('UP TO +2.5PP COMMUNITY UPLIFT', ArcUiTokens.secondaryAccent),
                _Chip('30-DAY VALIDATION', ArcUiTokens.primaryAccent),
                _Chip('PREMIUM CREATOR PRICE £7.99', ArcUiTokens.primaryAccent),
              ],
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          _LiveCreatorCommandCentre(repository: repository),
          const SizedBox(height: ArcUiTokens.gapM),
          const _LevelGrid(),
          const SizedBox(height: ArcUiTokens.gapM),
          const _CreatorTerms(),
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
          return const UagCreatorApplicationPanel();
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
              icon: Icons.radar_rounded,
              title: approved ? 'LIVE CREATOR DASHBOARD' : 'CREATOR APPLICATION',
              subtitle: approved
                  ? 'Identity, points, active paid audience, rate and earnings.'
                  : application.status.label,
              accent: approved
                  ? ArcUiTokens.secondaryAccent
                  : ArcUiTokens.primaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ArcUiTokens.gapS,
                    runSpacing: ArcUiTokens.gapS,
                    children: [
                      _Metric(
                        'CREATOR ID',
                        application.creatorId.isEmpty
                            ? 'Pending'
                            : application.creatorId,
                      ),
                      _Metric(
                        'POINTS',
                        dash.creatorPoints.toStringAsFixed(
                          dash.creatorPoints % 1 == 0 ? 0 : 1,
                        ),
                      ),
                      _Metric('LEVEL', dash.level?.name ?? 'Unranked'),
                      _Metric(
                        'BASE RATE',
                        '${_pct(dash.commissionPercent)}%',
                        accent: ArcUiTokens.secondaryAccent,
                      ),
                      _Metric('ESSENTIAL', '${dash.essentialSubscribers}'),
                      _Metric('PREMIUM', '${dash.premiumSubscribers}'),
                      _Metric(
                        'APPROVED EARNINGS',
                        '£${(dash.approvedCommissionPence / 100).toStringAsFixed(2)}',
                        accent: ArcUiTokens.success,
                      ),
                    ],
                  ),
                  if (approved) ...[
                    const SizedBox(height: ArcUiTokens.gapM),
                    UagCreatorCommissionRatePanel(
                      creatorPoints: dash.creatorPoints,
                    ),
                    const SizedBox(height: ArcUiTokens.gapM),
                    UagCreatorCommunityArsenalPanel(
                      inventory: dash.monthlyInventory,
                    ),
                    const SizedBox(height: ArcUiTokens.gapM),
                    const UagCreatorCommissionLedgerPanel(),
                    const SizedBox(height: ArcUiTokens.gapM),
                    const UagCreatorRewardAccessPanel(),
                    const SizedBox(height: ArcUiTokens.gapM),
                    _CampaignCodes(repository: repository),
                  ] else ...[
                    const SizedBox(height: ArcUiTokens.gapM),
                    const UagCreatorApplicationPanel(),
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

class _CampaignCodes extends StatelessWidget {
  const _CampaignCodes({required this.repository});

  final UagCreatorLiveRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UagCreatorCodeRecord>>(
      stream: repository.watchMyCodeRequests(),
      builder: (context, snapshot) {
        final codes = snapshot.data ?? const <UagCreatorCodeRecord>[];
        return Container(
          width: double.infinity,
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: ArcUiTokens.primaryAccent,
            borderOpacity: 0.2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAMPAIGN CODES',
                style: ArcUiTokens.cardTitle(
                  color: ArcUiTokens.primaryAccent,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              if (codes.isEmpty)
                Text(
                  'No creator campaign codes requested yet.',
                  style: ArcUiTokens.bodySmall(),
                )
              else
                Wrap(
                  spacing: ArcUiTokens.gapS,
                  runSpacing: ArcUiTokens.gapS,
                  children: [
                    for (final code in codes)
                      _Chip(
                        '${code.code} • ${code.status.replaceAll('_', ' ').toUpperCase()}',
                        ArcUiTokens.primaryAccent,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelGrid extends StatelessWidget {
  const _LevelGrid();

  @override
  Widget build(BuildContext context) {
    return ArcTacticalPanel(
      icon: Icons.stacked_line_chart_rounded,
      title: 'CREATOR COMMISSION LADDER',
      subtitle:
          'Active Creator Points set the base rate. Community Growth can add up to +2.5 percentage points.',
      accent: ArcUiTokens.secondaryAccent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 860
              ? 3
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          final width =
              (constraints.maxWidth - ((columns - 1) * ArcUiTokens.gapS)) /
              columns;
          return Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              for (final level in UagCreatorCommercialPolicy.levels)
                SizedBox(width: width, child: _LevelCard(level: level)),
            ],
          );
        },
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final UagCreatorLevel level;

  @override
  Widget build(BuildContext context) {
    final range = level.maxPoints == null
        ? '${level.minPoints.toStringAsFixed(0)}+'
        : '${level.minPoints.toStringAsFixed(0)}–${level.maxPoints!.floor()}';
    return Container(
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.secondaryAccent,
        borderOpacity: 0.22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.name.toUpperCase(),
            style: ArcUiTokens.cardTitle(color: ArcUiTokens.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            '$range POINTS',
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            '${_pct(level.commissionPercent)}% recurring',
            style: ArcUiTokens.numeric(
              fontSize: 17,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorTerms extends StatelessWidget {
  const _CreatorTerms();

  @override
  Widget build(BuildContext context) {
    return const ArcTacticalPanel(
      icon: Icons.shield_outlined,
      title: 'PROGRAMME RULES',
      subtitle: 'Commercial protections without the wall of text.',
      accent: ArcUiTokens.primaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rule('Commission is calculated from eligible net subscription revenue actually received.'),
          _Rule('Refunds, chargebacks, self-referrals and fraudulent referrals do not qualify.'),
          _Rule('Commission validates for 30 days before becoming payable.'),
          _Rule('Creator campaign discounts are separate from commission and do not stack unless UAG explicitly permits it.'),
          _Rule('A 30-day grace period protects Creator tier status from normal short-term subscriber churn.'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ArcUiTokens.primaryAccent;
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArcUiTokens.label()),
          const SizedBox(height: 3),
          Text(value, style: ArcUiTokens.numeric(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);

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

class _Rule extends StatelessWidget {
  const _Rule(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: ArcUiTokens.primaryAccent,
          ),
          const SizedBox(width: ArcUiTokens.gapS),
          Expanded(child: Text(text, style: ArcUiTokens.bodySmall())),
        ],
      ),
    );
  }
}

String _pct(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
