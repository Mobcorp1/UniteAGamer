import 'package:flutter/material.dart';

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

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'COMMUNITY GROWTH',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('$users qualified active Raiders'),
                const SizedBox(height: 8),
                Text(
                  uplift > 0
                      ? 'Creator community commission uplift: +${uplift.toStringAsFixed(1)}%'
                      : 'First Creator commission uplift unlocks at 10,000 qualified active Raiders.',
                ),
                if (nextTarget != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (users / nextTarget).clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text('Next community target: $nextTarget'),
                ],
              ],
            ),
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
