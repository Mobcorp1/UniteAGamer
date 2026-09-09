import 'package:flutter/material.dart';

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
            entitlement?.tier == UagSubscriptionTier.premium;

        return StreamBuilder<List<UagReferralBankedReward>>(
          stream: _repository.watchMyLocker(),
          builder: (context, lockerSnapshot) {
            final rewards =
                lockerSnapshot.data ?? const <UagReferralBankedReward>[];
            final active = rewards.where(
              (reward) => reward.status == UagReferralRewardStatus.active,
            );
            final banked = rewards.where(
              (reward) => reward.status == UagReferralRewardStatus.banked,
            );

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'REWARD LOCKER',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bank referral rewards and activate them when you know you will get the most value from them.',
                    ),
                    const SizedBox(height: 12),
                    if (active.isEmpty && banked.isEmpty)
                      const Text('No banked referral rewards yet.'),
                    for (final reward in active)
                      _RewardTile(
                        reward: reward,
                        active: true,
                        onActivate: null,
                      ),
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
                              SnackBar(
                                content: Text(
                                  '${reward.type.label} activated.',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Bad state: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    if (underlyingPremiumActive && banked.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Premium is already active, so banked rewards will stay safely stored until you choose to use them later.',
                      ),
                    ],
                  ],
                ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(reward.type.label),
      subtitle: Text(
        active
            ? 'ACTIVE • ends ${reward.expiresAtIso.isEmpty ? 'later' : reward.expiresAtIso}'
            : 'BANKED • activate when you are ready',
      ),
      trailing: active
          ? const Icon(Icons.timer_outlined)
          : FilledButton(onPressed: onActivate, child: const Text('ACTIVATE')),
    );
  }
}
