import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_creator_live_models.dart';
import '../models/uag_creator_reward_models.dart';
import '../repositories/uag_creator_reward_repository.dart';

class UagCreatorCommunityArsenalPanel extends StatefulWidget {
  const UagCreatorCommunityArsenalPanel({required this.inventory, super.key});

  final UagCreatorMonthlyInventory inventory;

  @override
  State<UagCreatorCommunityArsenalPanel> createState() =>
      _UagCreatorCommunityArsenalPanelState();
}

class _UagCreatorCommunityArsenalPanelState
    extends State<UagCreatorCommunityArsenalPanel> {
  final _repository = UagCreatorRewardRepository();
  final _redeemController = TextEditingController();
  bool _busy = false;
  String _message = '';

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  Future<void> _request(UagCreatorRewardType type) async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final code = await _repository.requestGiveawayCode(type);
      if (!mounted) return;
      setState(
        () => _message =
            '$code requested. Admin validation is required before it becomes active.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Could not load creator rewards. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await _repository.submitGiveawayRedemption(_redeemController.text);
      _redeemController.clear();
      if (!mounted) return;
      setState(() => _message = 'Redemption submitted for validation.');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message = 'Could not activate creator reward. Try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = widget.inventory;
    final available = <(UagCreatorRewardType, int)>[
      (UagCreatorRewardType.essential7Day, inventory.essential7DayRemaining),
      (UagCreatorRewardType.essentialMonth, inventory.essentialMonthRemaining),
      (UagCreatorRewardType.premium7Day, inventory.premium7DayRemaining),
      (UagCreatorRewardType.premiumMonth, inventory.premiumMonthRemaining),
      (UagCreatorRewardType.annualPremium, inventory.annualPremiumRemaining),
    ];

    return ArcTacticalPanel(
      icon: Icons.inventory_2_outlined,
      title: 'COMMUNITY ARSENAL',
      subtitle:
          'Creator giveaway inventory and validated reward redemptions.',
      accent: ArcUiTokens.secondaryAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GIVEAWAY CODE REQUESTS',
            style: ArcUiTokens.sectionTitle(
              fontSize: 13,
              color: ArcUiTokens.secondaryAccent,
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: [
              for (final item in available)
                if (item.$2 > 0)
                  OutlinedButton.icon(
                    style: ArcUiTokens.textButtonStyle(
                      accent: ArcUiTokens.secondaryAccent,
                    ),
                    onPressed: _busy ? null : () => _request(item.$1),
                    icon: const Icon(Icons.card_giftcard, size: 17),
                    label: Text('${item.$1.label} • ${item.$2} LEFT'),
                  ),
            ],
          ),
          if (available.every((item) => item.$2 <= 0))
            Text(
              'No giveaway inventory remains in the current Community Arsenal.',
              style: ArcUiTokens.bodySmall(),
            ),
          const SizedBox(height: ArcUiTokens.gapM),
          StreamBuilder<List<UagCreatorGiveawayCode>>(
            stream: _repository.watchMyGiveawayCodes(),
            builder: (context, snapshot) {
              final codes = snapshot.data ?? const <UagCreatorGiveawayCode>[];
              if (codes.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: ArcUiTokens.gapS,
                runSpacing: ArcUiTokens.gapS,
                children: codes
                    .take(8)
                    .map(
                      (code) => _CodeChip(
                        label:
                            '${code.code} • ${code.rewardType.label} • ${code.status.replaceAll('_', ' ')}',
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: ArcUiTokens.gapL),
          Divider(color: ArcUiTokens.borderSubtle, height: 1),
          const SizedBox(height: ArcUiTokens.gapL),
          Text(
            'REDEEM A CREATOR GIVEAWAY',
            style: ArcUiTokens.sectionTitle(
              fontSize: 13,
              color: ArcUiTokens.primaryAccent,
            ),
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final field = TextField(
                controller: _redeemController,
                textCapitalization: TextCapitalization.characters,
                style: ArcUiTokens.body(color: ArcUiTokens.textPrimary),
                decoration: ArcUiTokens.inputDecoration(
                  labelText: 'Giveaway code',
                  prefixIcon: Icons.confirmation_number_outlined,
                ),
              );
              final button = FilledButton(
                style: ArcUiTokens.textButtonStyle(
                  accent: ArcUiTokens.primaryAccent,
                  primary: true,
                ),
                onPressed: _busy ? null : _redeem,
                child: const Text('REDEEM'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: ArcUiTokens.gapS),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: ArcUiTokens.gapS),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            'Codes are single-use and expire. Submitted redemptions require UAG validation before access is granted.',
            style: ArcUiTokens.bodySmall(),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: ArcUiTokens.gapS),
            Text(
              _message,
              style: ArcUiTokens.bodySmall(color: ArcUiTokens.primaryAccent),
            ),
          ],
          StreamBuilder<List<UagCreatorRedemptionClaim>>(
            stream: _repository.watchMyRedemptions(),
            builder: (context, snapshot) {
              final claims = snapshot.data ?? const <UagCreatorRedemptionClaim>[];
              if (claims.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: ArcUiTokens.gapM),
                child: Wrap(
                  spacing: ArcUiTokens.gapS,
                  runSpacing: ArcUiTokens.gapS,
                  children: claims
                      .take(6)
                      .map(
                        (claim) => _CodeChip(
                          label:
                              '${claim.code} • ${claim.status.replaceAll('_', ' ')}',
                          accent: ArcUiTokens.primaryAccent,
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({
    required this.label,
    this.accent = ArcUiTokens.secondaryAccent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: accent),
      child: Text(
        label.toUpperCase(),
        style: ArcUiTokens.label(color: ArcUiTokens.textSecondary),
      ),
    );
  }
}
