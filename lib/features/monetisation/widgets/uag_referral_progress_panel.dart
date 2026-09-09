import 'package:flutter/material.dart';

import '../models/uag_community_referral_policy.dart';
import '../repositories/uag_referral_validation_repository.dart';

class UagReferralProgressPanel extends StatelessWidget {
  const UagReferralProgressPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UagReferralValidationRepository();

    return StreamBuilder<Map<String, dynamic>>(
      stream: repository.watchMyReferralProgress(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final validated = (data['validatedReferrals'] as num?)?.toInt() ?? 0;
        final pending = (data['pendingReferrals'] as num?)?.toInt() ?? 0;
        final next = UagCommunityReferralPolicy.nextMilestone(validated);
        final fastTrack = data['creatorFastTrackUnlocked'] == true;

        final target = next?.validatedReferrals ?? validated;
        final progress = next == null || target == 0
            ? 1.0
            : (validated / target).clamp(0.0, 1.0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'REFERRAL PROGRESS',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('$validated validated • $pending pending'),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                if (next != null)
                  Text(
                    'Next reward at ${next.validatedReferrals}: ${next.label}',
                  )
                else
                  const Text('All current Refer a Raider milestones unlocked.'),
                if (fastTrack) ...[
                  const SizedBox(height: 10),
                  const Text('Creator Programme fast-track review unlocked.'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
