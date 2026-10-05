import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_subscription_tier.dart';
import '../models/uag_user_entitlement.dart';
import '../services/uag_entitlement_service.dart';

class UagHubRewardsOverviewPanel extends StatefulWidget {
  const UagHubRewardsOverviewPanel({super.key});

  @override
  State<UagHubRewardsOverviewPanel> createState() =>
      _UagHubRewardsOverviewPanelState();
}

class _UagHubRewardsOverviewPanelState
    extends State<UagHubRewardsOverviewPanel> {
  late final UagEntitlementService _service = UagEntitlementService();

  static const _actions = <UagBillableAction>[
    UagBillableAction.trade,
    UagBillableAction.matchmakingSearch,
    UagBillableAction.premiumIntelUnlock,
    UagBillableAction.raidCompanionPreset,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagUserEntitlement>(
      stream: _service.watchMyEntitlement(),
      builder: (context, entitlementSnapshot) {
        final entitlement = entitlementSnapshot.data;
        if (entitlement == null) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<Map<String, int>>(
          stream: _service.watchCurrentMonthlyUsage(),
          builder: (context, usageSnapshot) {
            final usage = usageSnapshot.data ?? const <String, int>{};
            return StreamBuilder<Map<String, int>>(
              stream: _service.watchCurrentMonthlyBonuses(),
              builder: (context, bonusSnapshot) {
                final bonuses = bonusSnapshot.data ?? const <String, int>{};
                return ArcTacticalPanel(
                  icon: Icons.military_tech_rounded,
                  title: 'HUB OPERATIONS • ${_monthLabel(DateTime.now())}',
                  subtitle:
                      'Monthly action track • earn extra access through Hub Credits, referrals and Operations',
                  accent: Colors.amberAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: ArcUiTokens.gapS,
                        runSpacing: ArcUiTokens.gapS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _PlanBadge(tier: entitlement.effectiveTier),
                          Text(
                            _tierSummary(entitlement.effectiveTier),
                            style: ArcUiTokens.bodySmall(
                              color: ArcUiTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ArcUiTokens.gapM),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 4 : 2;
                          final gap = ArcUiTokens.gapS;
                          final width =
                              (constraints.maxWidth - ((columns - 1) * gap)) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: <Widget>[
                              for (final action in _actions)
                                SizedBox(
                                  width: width,
                                  child: _ActionCard(
                                    action: action,
                                    used: usage[action.usageKey] ?? 0,
                                    baseLimit: entitlement.limits.limitFor(
                                      action,
                                    ),
                                    bonus: bonuses[action.usageKey] ?? 0,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: ArcUiTokens.gapS),
                      Text(
                        'Opening pages never spends an action. A Trade is spent when you initiate an offer; Match Raider when you send a new invite; Raid Intelligence when you generate a route; Raid Planner when you refresh/run regional planning.',
                        style: ArcUiTokens.bodySmall(
                          color: ArcUiTokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static String _monthLabel(DateTime value) {
    const months = <String>[
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  static String _tierSummary(UagSubscriptionTier tier) => switch (tier) {
    UagSubscriptionTier.free =>
      'Free monthly base: 5 Trades • 5 Match • 5 Intel • 5 Raid Runs',
    UagSubscriptionTier.essential =>
      'Essential monthly base: 30 Trades • 30 Match • 30 Intel • 30 Raid Runs',
    UagSubscriptionTier.premium =>
      'Premium: unlimited core Trades, Match, Raid Intelligence and Raid Planner runs',
  };
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.tier});

  final UagSubscriptionTier tier;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tier) {
      UagSubscriptionTier.free => ArcUiTokens.textSecondary,
      UagSubscriptionTier.essential => ArcUiTokens.primaryAccent,
      UagSubscriptionTier.premium => ArcUiTokens.secondaryAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        tier.publicName.toUpperCase(),
        style: ArcUiTokens.label(color: accent),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.used,
    required this.baseLimit,
    required this.bonus,
  });

  final UagBillableAction action;
  final int used;
  final int? baseLimit;
  final int bonus;

  @override
  Widget build(BuildContext context) {
    final total = baseLimit == null
        ? null
        : baseLimit! + (bonus < 0 ? 0 : bonus);
    final remaining = total == null ? null : (total - used).clamp(0, total);
    final fraction = total == null || total <= 0
        ? 1.0
        : (used / total).clamp(0.0, 1.0);
    final icon = switch (action) {
      UagBillableAction.trade => Icons.swap_horiz_rounded,
      UagBillableAction.matchmakingSearch => Icons.groups_2_rounded,
      UagBillableAction.premiumIntelUnlock => Icons.radar_rounded,
      UagBillableAction.raidCompanionPreset => Icons.route_rounded,
      _ => Icons.bolt_rounded,
    };
    final shortLabel = switch (action) {
      UagBillableAction.trade => 'TRADES',
      UagBillableAction.matchmakingSearch => 'MATCH RAIDER',
      UagBillableAction.premiumIntelUnlock => 'RAID INTEL',
      UagBillableAction.raidCompanionPreset => 'RAID RUNS',
      _ => action.label.toUpperCase(),
    };

    return Container(
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: ArcUiTokens.primaryAccent,
        borderOpacity: 0.20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: ArcUiTokens.primaryAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            total == null ? '∞' : '$remaining LEFT',
            style: ArcUiTokens.numeric(
              fontSize: 18,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: ArcUiTokens.surfaceOverlay,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            total == null
                ? 'Unlimited this month'
                : '$used / $total used${bonus > 0 ? ' • +$bonus earned' : ''}',
            style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
          ),
        ],
      ),
    );
  }
}
