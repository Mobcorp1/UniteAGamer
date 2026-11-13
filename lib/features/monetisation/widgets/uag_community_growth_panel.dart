import 'package:flutter/material.dart';

import '../models/uag_community_referral_policy.dart';

class UagCommunityGrowthPanel extends StatelessWidget {
  const UagCommunityGrowthPanel({super.key, this.qualifiedActiveUsers = 0});

  final int qualifiedActiveUsers;

  @override
  Widget build(BuildContext context) {
    final next = UagCommunityGrowthPolicy.nextTarget(qualifiedActiveUsers);
    final bonus = UagCommunityGrowthPolicy.creatorGrowthBonusPercent(
      qualifiedActiveUsers,
    );
    final progress = next == null
        ? 1.0
        : (qualifiedActiveUsers / next).clamp(0.0, 1.0);

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
            const Text(
              'When the UAG community grows sustainably, the people helping build it unlock better rewards too.',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? '$qualifiedActiveUsers qualified active Raiders'
                  : '$qualifiedActiveUsers / $next qualified active Raiders',
            ),
            const SizedBox(height: 8),
            Text(
              bonus > 0
                  ? 'Current Creator Community Growth Bonus: +${bonus.toStringAsFixed(1)} percentage points'
                  : 'First Creator Community Growth Bonus unlocks at 10,000 qualified active Raiders.',
            ),
            const SizedBox(height: 6),
            const Text(
              'Annual Community Success rewards can be funded only when UAG reaches sustainable commercial thresholds. They are rewards, not equity or dividends.',
            ),
          ],
        ),
      ),
    );
  }
}
