import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_creator_commission_rate_policy.dart';
import '../repositories/uag_community_growth_repository.dart';

class UagCommunityGrowthLivePanel extends StatelessWidget {
  const UagCommunityGrowthLivePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagCommunityGrowthRepository();

    return StreamBuilder(
      stream: repository.watch(),
      builder: (context, snapshot) {
        final users = snapshot.data?.qualifiedActiveUsers ?? 0;
        final uplift = UagCreatorCommissionRatePolicy.communityUpliftPercent(
          users,
        );
        final nextTarget = _nextTarget(users);

        return ArcTacticalPanel(
          icon: Icons.groups_3_outlined,
          title: 'COMMUNITY GROWTH',
          subtitle: '$users qualified active Raiders',
          accent: ArcUiTokens.secondaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uplift > 0
                    ? 'Creator community uplift: +${_pct(uplift)} percentage points.'
                    : 'Creator community uplift begins at 10,000 qualified active Raiders.',
                style: ArcUiTokens.bodySmall(),
              ),
              if (nextTarget != null) ...[
                const SizedBox(height: ArcUiTokens.gapS),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (users / nextTarget).clamp(0.0, 1.0),
                    minHeight: 7,
                    color: ArcUiTokens.secondaryAccent,
                    backgroundColor:
                        ArcUiTokens.secondaryAccent.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapXS),
                Text(
                  'Next community target: $nextTarget',
                  style: ArcUiTokens.metadata(
                    color: ArcUiTokens.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  int? _nextTarget(int users) {
    const targets = <int>[10000, 25000, 50000, 100000, 250000];
    for (final target in targets) {
      if (users < target) return target;
    }
    return null;
  }
}

String _pct(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
