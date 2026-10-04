import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../services/uag_referral_action_reward_service.dart';

class UagReferralChallengePanel extends StatefulWidget {
  const UagReferralChallengePanel({super.key});

  @override
  State<UagReferralChallengePanel> createState() =>
      _UagReferralChallengePanelState();
}

class _UagReferralChallengePanelState extends State<UagReferralChallengePanel> {
  final UagReferralActionRewardService _service =
      UagReferralActionRewardService();
  final Map<UagReferralActionRewardTarget, String> _retryIds =
      <UagReferralActionRewardTarget, String>{};
  bool _busy = false;
  String? _message;

  Future<void> _redeem(UagReferralActionRewardTarget target) async {
    if (_busy) return;
    final requestId = _retryIds.putIfAbsent(
      target,
      UagReferralActionRewardService.newRequestId,
    );
    setState(() {
      _busy = true;
      _message = 'Redeeming referral bonus…';
    });
    try {
      await _service.redeem(target, requestId: requestId);
      _retryIds.remove(target);
      if (!mounted) return;
      setState(() => _message = '${target.label} added to this month.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is UagReferralActionRewardException
            ? error.message
            : 'Referral reward could not be confirmed. Retry safely.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagReferralActionRewardState>(
      stream: _service.watchCurrentMonth(),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const UagReferralActionRewardState();
        return ArcTacticalPanel(
          icon: Icons.route_rounded,
          title: 'RECRUITMENT DRIVE',
          subtitle:
              'Monthly referral challenge • genuine validated Raiders only',
          accent: ArcUiTokens.primaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ChallengeTrack(
                label: 'FREE RAIDERS',
                progress: state.freeProgress,
                target: 10,
                lifetimeCount: state.freeQualifiedCount,
                detail: 'Every 10 validated referrals = 1 Bonus Action',
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              _ChallengeTrack(
                label: 'PAID RAIDERS',
                progress: state.paidProgress,
                target: 5,
                lifetimeCount: state.paidQualifiedCount,
                detail: 'Every 5 first-time paid referrals = 1 Bonus Action',
                accent: ArcUiTokens.secondaryAccent,
              ),
              const SizedBox(height: ArcUiTokens.gapM),
              Wrap(
                spacing: ArcUiTokens.gapS,
                runSpacing: ArcUiTokens.gapS,
                children: <Widget>[
                  _Stat(label: 'EARNED', value: '${state.earnedTokens}'),
                  _Stat(label: 'REDEEMED', value: '${state.redeemedTokens}'),
                  _Stat(
                    label: 'READY',
                    value: '${state.availableTokens}',
                    accent: state.availableTokens > 0
                        ? ArcUiTokens.success
                        : ArcUiTokens.textTertiary,
                  ),
                ],
              ),
              if (state.availableTokens > 0 ||
                  _retryIds.isNotEmpty) ...<Widget>[
                const SizedBox(height: ArcUiTokens.gapM),
                Text(
                  'Choose each earned Bonus Action:',
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                Wrap(
                  spacing: ArcUiTokens.gapS,
                  runSpacing: ArcUiTokens.gapS,
                  children: <Widget>[
                    for (final target in UagReferralActionRewardTarget.values)
                      OutlinedButton(
                        onPressed:
                            !_busy &&
                                (state.availableTokens > 0 ||
                                    _retryIds.containsKey(target))
                            ? () => _redeem(target)
                            : null,
                        child: Text(
                          _retryIds.containsKey(target)
                              ? 'Retry ${target.label}'
                              : target.label,
                        ),
                      ),
                  ],
                ),
              ],
              if (_message != null) ...<Widget>[
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  _message!,
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
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

class _ChallengeTrack extends StatelessWidget {
  const _ChallengeTrack({
    required this.label,
    required this.progress,
    required this.target,
    required this.lifetimeCount,
    required this.detail,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String label;
  final int progress;
  final int target;
  final int lifetimeCount;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fraction = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
    final remaining = (target - progress).clamp(0, target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: ArcUiTokens.label(color: accent)),
            ),
            Text(
              '$progress / $target',
              style: ArcUiTokens.numeric(fontSize: 15, color: accent),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: fraction,
            backgroundColor: ArcUiTokens.surfaceOverlay,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          remaining == 0
              ? '$detail • reward threshold reached'
              : '$detail • $remaining remaining • $lifetimeCount qualified this month',
          style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ArcUiTokens.primaryAccent;
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: ArcUiTokens.compactPanelPadding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.raised,
        accent: color,
        borderOpacity: 0.22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(value, style: ArcUiTokens.numeric(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
