import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_referral_reward_locker_models.dart';
import '../models/uag_subscription_tier.dart';
import '../models/uag_user_entitlement.dart';
import '../repositories/uag_referral_reward_locker_repository.dart';
import '../services/uag_entitlement_service.dart';

class UagReferralRewardLockerPanel extends StatefulWidget {
  const UagReferralRewardLockerPanel({super.key});

  @override
  State<UagReferralRewardLockerPanel> createState() =>
      _UagReferralRewardLockerPanelState();
}

class _UagReferralRewardLockerPanelState
    extends State<UagReferralRewardLockerPanel> {
  final _repository = UagReferralRewardLockerRepository();
  final _entitlementService = UagEntitlementService();

  @override
  void initState() {
    super.initState();
    _repository.sweepExpiredRewards();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagUserEntitlement>(
      stream: _entitlementService.watchMyEntitlement(),
      builder: (context, entitlementSnapshot) {
        final entitlement = entitlementSnapshot.data;
        final underlyingPremiumActive =
            entitlement?.effectiveTier == UagSubscriptionTier.premium;

        return StreamBuilder<List<UagReferralBankedReward>>(
          stream: _repository.watchMyLocker(),
          builder: (context, lockerSnapshot) {
            final rewards =
                lockerSnapshot.data ?? const <UagReferralBankedReward>[];
            final active = rewards
                .where((reward) => reward.status == UagReferralRewardStatus.active)
                .toList(growable: false);
            final banked = rewards
                .where((reward) => reward.status == UagReferralRewardStatus.banked)
                .toList(growable: false);

            return ArcTacticalPanel(
              icon: Icons.inventory_2_outlined,
              title: 'REWARD LOCKER',
              subtitle:
                  'Bank Premium rewards and activate them when they are useful to you.',
              accent: ArcUiTokens.secondaryAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isEmpty && banked.isEmpty)
                    Text(
                      'No banked referral rewards yet.',
                      style: ArcUiTokens.bodySmall(),
                    ),
                  for (final reward in active)
                    _RewardTile(reward: reward, active: true, onActivate: null),
                  for (final reward in banked)
                    _RewardTile(
                      reward: reward,
                      active: false,
                      onActivate: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _repository.activateReward(
                            rewardId: reward.id,
                            underlyingPremiumActive: underlyingPremiumActive,
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('${reward.type.label} activated.')),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst('Bad state: ', ''),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (underlyingPremiumActive && banked.isNotEmpty) ...[
                    const SizedBox(height: ArcUiTokens.gapS),
                    Text(
                      'Premium is already active, so banked rewards stay stored until you choose to use them later.',
                      style: ArcUiTokens.bodySmall(
                        color: ArcUiTokens.textTertiary,
                      ),
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

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.reward,
    required this.active,
    required this.onActivate,
  });

  final UagReferralBankedReward reward;
  final bool active;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final accent = active ? ArcUiTokens.success : ArcUiTokens.secondaryAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: ArcUiTokens.gapS),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: accent,
        borderOpacity: 0.22,
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.timer_outlined : Icons.redeem_outlined,
            color: accent,
          ),
          const SizedBox(width: ArcUiTokens.gapS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.type.label,
                  style: ArcUiTokens.cardTitle(color: ArcUiTokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? 'ACTIVE • ends ${reward.expiresAtIso.isEmpty ? 'later' : reward.expiresAtIso}'
                      : 'BANKED • activate when you are ready',
                  style: ArcUiTokens.metadata(color: ArcUiTokens.textTertiary),
                ),
              ],
            ),
          ),
          if (!active)
            OutlinedButton(
              style: ArcUiTokens.textButtonStyle(accent: accent),
              onPressed: onActivate,
              child: const Text('ACTIVATE'),
            ),
        ],
      ),
    );
  }
}
