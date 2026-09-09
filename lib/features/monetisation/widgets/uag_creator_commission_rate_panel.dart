import 'package:flutter/material.dart';

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

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CREATOR COMMISSION RATE',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Creator Points: ${creatorPoints.toStringAsFixed(1)}'),
                Text('Base rate: ${base.toStringAsFixed(1)}%'),
                Text('Community uplift: +${uplift.toStringAsFixed(1)}%'),
                Text(
                  'Effective rate: ${effective.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
