import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/monetisation/models/uag_monetisation_models.dart';
import 'package:uag_traders_hub/features/monetisation/repositories/uag_monetisation_repository.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class UagImpactPotsPanel extends StatelessWidget {
  const UagImpactPotsPanel({super.key, required this.showAdminDetail});

  final bool showAdminDetail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UagImpactPotSnapshot>>(
      stream: UagMonetisationRepository().watchImpactPots(),
      builder: (context, snapshot) {
        final pots = snapshot.data ?? const <UagImpactPotSnapshot>[];
        final essential = _findPot(pots, 'essential');
        final premium = _findPot(pots, 'premium');
        return Container(
          padding: AppTheme.sectionCardPadding,
          decoration: AppTheme.tradingCardDecoration(
            borderColor: AppTheme.neonPink.withValues(alpha: 0.22),
            radius: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UAG Impact Pots',
                style: AppTheme.tradingHeading(fontSize: 24, color: AppTheme.neonPink),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                'Essential contributes 10% of net platform profit. Premium contributes 20% of net platform profit. This is held as an impact pot for future charitable causes and wishlist fulfilment.',
                style: AppTheme.bodyTextStyle(fontSize: 14, color: AppTheme.tradingMutedText),
              ),
              const SizedBox(height: AppTheme.spaceM),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final cards = [
                    _ImpactPotCard(title: 'Essential Impact Pot', pot: essential, color: AppTheme.neonCyan, percent: 10, showAdminDetail: showAdminDetail),
                    _ImpactPotCard(title: 'Premium Impact Pot', pot: premium, color: AppTheme.neonPink, percent: 20, showAdminDetail: showAdminDetail),
                  ];
                  if (!isWide) {
                    return Column(children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: AppTheme.spaceM), child: card)).toList());
                  }
                  return Row(children: cards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppTheme.spaceM), child: card))).toList());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  UagImpactPotSnapshot? _findPot(List<UagImpactPotSnapshot> pots, String id) {
    for (final pot in pots) {
      if (pot.id == id) return pot;
    }
    return null;
  }
}

class _ImpactPotCard extends StatelessWidget {
  const _ImpactPotCard({required this.title, required this.pot, required this.color, required this.percent, required this.showAdminDetail});

  final String title;
  final UagImpactPotSnapshot? pot;
  final Color color;
  final int percent;
  final bool showAdminDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(borderColor: color.withValues(alpha: 0.22), radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.tradingHeading(fontSize: 20, color: color)),
          const SizedBox(height: AppTheme.spaceS),
          Text('$percent% of net profit', style: AppTheme.bodyTextStyle(fontSize: 13, color: AppTheme.tradingMutedText, isBold: true)),
          const SizedBox(height: AppTheme.spaceM),
          _row('This month', _money(pot?.monthlyPence ?? 0)),
          _row('All-time', _money(pot?.allTimePence ?? 0)),
          if (showAdminDetail) ...[
            _row('Contributors', '${pot?.contributingUsers ?? 0}'),
            _row('Last allocation', _date(pot?.lastAllocatedAt)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white60))),
          Text(value, style: AppTheme.bodyTextStyle(fontSize: 13, color: Colors.white, isBold: true)),
        ],
      ),
    );
  }

  String _money(int pence) => '£${(pence / 100).toStringAsFixed(2)}';

  String _date(DateTime? date) {
    if (date == null) return 'Not allocated yet';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
