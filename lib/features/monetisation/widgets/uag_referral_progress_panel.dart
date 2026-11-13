import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

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

        return ArcTacticalPanel(
          icon: Icons.route_outlined,
          title: 'REFERRAL PROGRESS',
          subtitle: '$validated validated • $pending pending',
          accent: ArcUiTokens.primaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: ArcUiTokens.primaryAccent,
                  backgroundColor:
                      ArcUiTokens.primaryAccent.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: ArcUiTokens.gapS),
              Text(
                next != null
                    ? 'Next community reward at ${next.validatedReferrals}: ${next.label}'
                    : 'All current Refer a Raider community milestones unlocked.',
                style: ArcUiTokens.bodySmall(),
              ),
              if (fastTrack) ...[
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'Creator Programme fast-track review unlocked.',
                  style: ArcUiTokens.metadata(
                    color: ArcUiTokens.secondaryAccent,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
