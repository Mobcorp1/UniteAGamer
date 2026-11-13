import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_creator_reward_activation_policy.dart';
import '../models/uag_creator_temporary_entitlement.dart';
import '../services/uag_entitlement_service.dart';

class UagCreatorRewardAccessPanel extends StatelessWidget {
  const UagCreatorRewardAccessPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: UagEntitlementService().watchMyEntitlement(),
      builder: (context, snapshot) {
        final entitlement = snapshot.data;
        if (entitlement == null) return const SizedBox.shrink();

        final grants = List<UagCreatorTemporaryEntitlement>.from(
          entitlement.creatorRewardEntitlements,
        )..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
        if (grants.isEmpty) return const SizedBox.shrink();

        final active = grants.where((grant) => grant.active).toList();
        final expired = grants.where((grant) => !grant.active).take(3).toList();

        return ArcTacticalPanel(
          icon: Icons.card_giftcard_outlined,
          title: 'Creator Reward Access',
          subtitle: active.isEmpty
              ? 'Your previous Community Arsenal access has expired.'
              : 'Community Arsenal access is active on this account.',
          accent: active.isEmpty
              ? ArcUiTokens.mutedText
              : ArcUiTokens.secondaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (active.isNotEmpty) ...[
                for (final grant in active) _GrantRow(grant: grant),
              ] else
                const Text(
                  'No creator reward is currently changing your access tier.',
                ),
              if (expired.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'RECENTLY EXPIRED',
                  style: ArcUiTokens.label(color: ArcUiTokens.textTertiary),
                ),
                const SizedBox(height: 6),
                for (final grant in expired)
                  _GrantRow(grant: grant, compact: true),
              ],
              const SizedBox(height: 8),
              Text(
                'Creator rewards never overwrite your paid subscription. When a reward expires, access automatically falls back to your underlying plan.',
                style: ArcUiTokens.bodySmall(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GrantRow extends StatelessWidget {
  const _GrantRow({required this.grant, this.compact = false});

  final UagCreatorTemporaryEntitlement grant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = UagCreatorRewardActivationPolicy.lifecycleState(
      startedAt: grant.startedAt,
      expiresAt: grant.expiresAt,
    );
    final active = state == 'active';
    final title = grant.rewardType.trim().isEmpty
        ? grant.tier.label
        : _rewardLabel(grant.rewardType);
    final status = active
        ? 'ACTIVE UNTIL ${_date(grant.expiresAt)}'
        : state == 'scheduled'
        ? 'STARTS ${_date(grant.startedAt)}'
        : 'EXPIRED ${_date(grant.expiresAt)}';

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 5 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (active ? ArcUiTokens.secondaryAccent : ArcUiTokens.mutedText)
              .withValues(alpha: .32),
        ),
        color: Colors.black.withValues(alpha: .14),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.bolt : Icons.history,
            size: 18,
            color: active ? ArcUiTokens.secondaryAccent : ArcUiTokens.mutedText,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArcUiTokens.cardTitle(fontSize: compact ? 12 : 13),
                ),
                const SizedBox(height: 2),
                Text(status, style: ArcUiTokens.metadata()),
              ],
            ),
          ),
          if (!compact)
            Text(
              grant.tier.label.toUpperCase(),
              style: ArcUiTokens.label(
                color: active
                    ? ArcUiTokens.secondaryAccent
                    : ArcUiTokens.mutedText,
              ),
            ),
        ],
      ),
    );
  }

  static String _rewardLabel(String value) => switch (value) {
    'essential_7_day' => 'Essential • 7 Day Creator Reward',
    'essential_month' => 'Essential • 30 Day Creator Reward',
    'premium_7_day' => 'Premium • 7 Day Creator Reward',
    'premium_month' => 'Premium • 30 Day Creator Reward',
    'annual_premium' => 'Premium • Annual Creator Reward',
    _ => value.replaceAll('_', ' '),
  };

  static String _date(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
