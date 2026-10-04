import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_subscription_tier.dart';
import '../models/uag_user_entitlement.dart';
import '../services/uag_entitlement_service.dart';
import '../services/uag_operation_action_reward_service.dart';

class UagOperationCompletionPanel extends StatefulWidget {
  const UagOperationCompletionPanel({super.key});

  @override
  State<UagOperationCompletionPanel> createState() =>
      _UagOperationCompletionPanelState();
}

class _UagOperationCompletionPanelState
    extends State<UagOperationCompletionPanel> {
  final _rewards = UagOperationActionRewardService();
  final _entitlements = UagEntitlementService();
  bool _busy = false;

  Future<void> _redeem(UagOperationCompletionTarget target) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _rewards.redeemCompletion(target);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${target.label} added to this month.')),
      );
    } on UagOperationActionRewardException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UagUserEntitlement>(
      stream: _entitlements.watchMyEntitlement(),
      builder: (context, entitlementSnapshot) {
        final entitlement = entitlementSnapshot.data;
        if (entitlement == null ||
            entitlement.effectiveTier == UagSubscriptionTier.premium) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<UagOperationCompletionState>(
          stream: _rewards.watchCurrentMonthCompletion(),
          builder: (context, snapshot) {
            final state = snapshot.data ?? const UagOperationCompletionState();
            return ArcTacticalPanel(
              icon: Icons.emoji_events_rounded,
              title: 'OPERATION COMPLETE',
              subtitle:
                  'Finish Trader, Squad Up, Field Intelligence and Raid Runner in the same monthly rotation.',
              accent: Colors.amberAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (state.completed / state.total).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 8,
                            backgroundColor: ArcUiTokens.surfaceOverlay,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: ArcUiTokens.gapS),
                      Text(
                        '${state.completed} / ${state.total}',
                        style: ArcUiTokens.numeric(
                          fontSize: 16,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ArcUiTokens.gapS),
                  Text(
                    state.redeemed
                        ? 'Monthly completion reward claimed.'
                        : state.ready
                        ? 'All four complete. Choose one Universal Bonus Action.'
                        : 'Complete all four to unlock one Universal Bonus Action.',
                    style: ArcUiTokens.bodySmall(
                      color: state.ready
                          ? ArcUiTokens.textPrimary
                          : ArcUiTokens.textSecondary,
                    ),
                  ),
                  if (state.ready) ...<Widget>[
                    const SizedBox(height: ArcUiTokens.gapM),
                    Wrap(
                      spacing: ArcUiTokens.gapS,
                      runSpacing: ArcUiTokens.gapS,
                      children: <Widget>[
                        for (final target
                            in UagOperationCompletionTarget.values)
                          OutlinedButton(
                            onPressed: _busy ? null : () => _redeem(target),
                            child: Text(target.label.toUpperCase()),
                          ),
                      ],
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
