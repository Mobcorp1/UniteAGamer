import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

import '../models/uag_creator_commission_rate_policy.dart';
import '../repositories/uag_community_growth_repository.dart';

class UagCreatorCommissionRatePanel extends StatelessWidget {
  const UagCreatorCommissionRatePanel({super.key, required this.creatorPoints});

  final double creatorPoints;

  @override
  Widget build(BuildContext context) {
    final repository = UagCommunityGrowthRepository();

    return StreamBuilder(
      stream: repository.watch(),
      builder: (context, snapshot) {
        final users = snapshot.data?.qualifiedActiveUsers ?? 0;
        final base = UagCreatorCommissionRatePolicy.baseRatePercent(
          creatorPoints,
        );
        final uplift = UagCreatorCommissionRatePolicy.communityUpliftPercent(
          users,
        );
        final effective = UagCreatorCommissionRatePolicy.effectiveRatePercent(
          points: creatorPoints,
          qualifiedActiveUsers: users,
        );

        return Container(
          width: double.infinity,
          padding: ArcUiTokens.panelPadding,
          decoration: ArcUiTokens.surfaceDecoration(
            role: ArcSurfaceRole.raised,
            accent: ArcUiTokens.secondaryAccent,
            borderOpacity: 0.24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREATOR COMMISSION RATE',
                style: ArcUiTokens.cardTitle(
                  color: ArcUiTokens.secondaryAccent,
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              Wrap(
                spacing: ArcUiTokens.gapS,
                runSpacing: ArcUiTokens.gapS,
                children: [
                  _RateStat('POINTS', creatorPoints.toStringAsFixed(1)),
                  _RateStat('BASE', '${_pct(base)}%'),
                  _RateStat('COMMUNITY', '+${_pct(uplift)}pp'),
                  _RateStat(
                    'EFFECTIVE',
                    '${_pct(effective)}%',
                    accent: ArcUiTokens.secondaryAccent,
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

class _RateStat extends StatelessWidget {
  const _RateStat(this.label, this.value, {this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ArcUiTokens.primaryAccent;
    return Container(
      constraints: const BoxConstraints(minWidth: 116),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.interactive,
        accent: color,
        borderOpacity: 0.2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ArcUiTokens.label()),
          const SizedBox(height: 2),
          Text(value, style: ArcUiTokens.numeric(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

String _pct(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
