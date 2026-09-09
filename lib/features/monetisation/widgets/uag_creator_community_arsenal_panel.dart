import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GIVEAWAY CODE REQUESTS',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in available)
              if (item.$2 > 0)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _request(item.$1),
                  icon: const Icon(Icons.card_giftcard, size: 17),
                  label: Text('${item.$1.label} • ${item.$2} left'),
                ),
          ],
        ),
        if (available.every((item) => item.$2 <= 0))
          const Text(
            'No giveaway inventory remains in the current Community Arsenal.',
          ),
        const SizedBox(height: 12),
        StreamBuilder<List<UagCreatorGiveawayCode>>(
          stream: _repository.watchMyGiveawayCodes(),
          builder: (context, snapshot) {
            final codes = snapshot.data ?? const <UagCreatorGiveawayCode>[];
            if (codes.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: codes
                  .take(8)
                  .map(
                    (code) => Chip(
                      label: Text(
                        '${code.code} • ${code.rewardType.label} • ${code.status.replaceAll('_', ' ')}',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const Divider(height: 26),
        const Text(
          'REDEEM A CREATOR GIVEAWAY',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _redeemController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Giveaway code'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _redeem,
              child: const Text('REDEEM'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Codes are single-use and expire. A submitted redemption does not grant access until UAG validates the code.',
        ),
        if (_message.isNotEmpty) ...[const SizedBox(height: 8), Text(_message)],
        StreamBuilder<List<UagCreatorRedemptionClaim>>(
          stream: _repository.watchMyRedemptions(),
          builder: (context, snapshot) {
            final claims = snapshot.data ?? const <UagCreatorRedemptionClaim>[];
            if (claims.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: claims
                    .take(6)
                    .map(
                      (claim) => Chip(
                        label: Text(
                          '${claim.code} • ${claim.status.replaceAll('_', ' ')}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
