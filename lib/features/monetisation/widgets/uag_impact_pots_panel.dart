import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/arc_tactical_page.dart';

import '../models/uag_monetisation_models.dart';
import '../repositories/uag_monetisation_repository.dart';

class UagImpactPotsPanel extends StatelessWidget {
  const UagImpactPotsPanel({super.key, required this.showAdminDetail});

  final bool showAdminDetail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UagImpactPotSnapshot>>(
      stream: UagMonetisationRepository().watchImpactPots(),
      builder: (context, snapshot) {
        final pots = snapshot.data ?? const <UagImpactPotSnapshot>[];
        final historicalTotal = pots.fold<int>(
          0,
          (total, pot) => total + pot.allTimePence,
        );
        return ArcTacticalPanel(
          icon: Icons.volunteer_activism_outlined,
          title: 'COMMUNITY IMPACT RESERVE',
          subtitle:
              'Automatic subscription percentage deductions are disabled. Future giving is funded from real operating profit under an admin-controlled staged policy.',
          accent: ArcUiTokens.secondaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historical impact-pot balance: £${(historicalTotal / 100).toStringAsFixed(2)}',
                style: ArcUiTokens.numeric(
                  fontSize: 17,
                  color: ArcUiTokens.secondaryAccent,
                ),
              ),
              if (showAdminDetail) ...[
                const SizedBox(height: ArcUiTokens.gapS),
                Text(
                  'No new Essential/Premium invoice is automatically split into charity pots. Any future allocation must be based on verified operating profit and an explicit UAG impact decision.',
                  style: ArcUiTokens.bodySmall(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
